#!/usr/bin/env python3
"""Genera los efectos de sonido del juego por síntesis (sin recursos de terceros).

Uso: python3 tools/generar_sonidos.py   -> escribe assets/sonidos/<nombre>.wav (mono, 44,1 kHz, 16 bits)

Cada sonido es una función que devuelve un array de muestras; las variantes (_1, _2...) cambian la
semilla y algún parámetro para que los sonidos repetidos (disparo, impacto...) no suenen idénticos.
Todos se normalizan a la misma sonoridad en un altavoz de móvil (SONORIDAD: RMS de los 100 ms más
fuertes tras quitar lo que hay por debajo de 900 Hz, que ese altavoz casi no reproduce), con el pico
limitado a -1 dBFS. Así el volumen de cada uno en Sonidos.EFECTOS (dB) es relativo y comparable.
La música (assets/musica) da unos -25 dB medidos igual.
"""
import os
import numpy as np
from scipy import signal
from scipy.io import wavfile

SR = 44100
#sonoridad objetivo en el altavoz del móvil (dBFS) y ganancia máxima para llegar a ella
SONORIDAD = -14.0
GANANCIA_MAX_DB = 18.0
DESTINO = os.path.join(os.path.dirname(__file__), "..", "assets", "sonidos")
rng = np.random.default_rng(1)


# ---------- utilidades ----------

def t(dur):
    return np.arange(int(SR * dur)) / SR

def ruido(dur):
    return rng.uniform(-1, 1, int(SR * dur))

def ruido_marron(dur):
    r = np.cumsum(rng.uniform(-1, 1, int(SR * dur)))
    r = filtro(r, "highpass", 20)
    return r / (np.max(np.abs(r)) + 1e-9)

def filtro(x, tipo, f, orden=4):
    sos = signal.butter(orden, f, btype=tipo, fs=SR, output="sos")
    return signal.sosfilt(sos, x)

def filtro_barrido(x, f0, f1, tipo="lowpass", trozos=64):
    """filtro que cambia de frecuencia a lo largo del sonido (por bloques con fundido)"""
    n = len(x)
    salida = np.zeros(n)
    bloque = max(1, n // trozos)
    zi = None
    for i in range(0, n, bloque):
        k = i / max(1, n - 1)
        f = f0 * (f1 / f0) ** k
        sos = signal.butter(2, f, btype=tipo, fs=SR, output="sos")
        if zi is None:
            zi = signal.sosfilt_zi(sos) * 0
        trozo, zi = signal.sosfilt(sos, x[i:i + bloque], zi=zi)
        salida[i:i + bloque] = trozo
    return salida

def env(dur, ataque=0.005, caida=None, curva=4.0):
    """envolvente: subida lineal y caída exponencial hasta el final"""
    n = int(SR * dur)
    e = np.ones(n)
    a = max(1, int(SR * ataque))
    e[:a] = np.linspace(0, 1, a)
    resto = n - a
    if resto > 0:
        e[a:] = np.exp(-curva * np.linspace(0, 1, resto))
    return fin_suave(e)

def fin_suave(x, seg=0.005):
    """los últimos milisegundos a cero: una pieza cortada en seco suena como un chasquido"""
    n = min(len(x) // 3, int(SR * seg))
    if n > 0:
        x[-n:] *= np.linspace(1, 0, n)
    return x

def tono(f0, f1, dur, forma="sin"):
    """oscilador con barrido exponencial de frecuencia"""
    tt = t(dur)
    f = f0 * (f1 / f0) ** (tt / dur)
    fase = 2 * np.pi * np.cumsum(f) / SR
    if forma == "sin":
        return np.sin(fase)
    if forma == "tri":
        return 2 / np.pi * np.arcsin(np.sin(fase))
    if forma == "saw":
        return 2 * ((fase / (2 * np.pi)) % 1) - 1
    if forma == "sq":
        return np.sign(np.sin(fase))
    raise ValueError(forma)

def campana(f, dur, caida=6.0):
    """tono metálico: parciales inarmónicos que caen a distinto ritmo"""
    tt = t(dur)
    s = np.zeros_like(tt)
    for mult, amp, c in [(1, 1.0, 1.0), (2.0, 0.5, 1.6), (2.76, 0.35, 2.2), (5.4, 0.2, 3.5), (8.9, 0.1, 5.0)]:
        s += amp * np.sin(2 * np.pi * f * mult * tt) * np.exp(-caida * c * tt)
    a = int(SR * 0.002)
    s[:a] *= np.linspace(0, 1, a)
    return fin_suave(s, 0.01)

def cuerda(f, dur, brillo=0.5):
    """cuerda pulsada (Karplus-Strong)"""
    n = int(SR * dur)
    periodo = int(SR / f)
    buf = rng.uniform(-1, 1, periodo)
    buf = filtro(buf, "lowpass", 2000 + 6000 * brillo, 2)
    salida = np.zeros(n)
    for i in range(n):
        salida[i] = buf[i % periodo]
        buf[i % periodo] = 0.996 * 0.5 * (buf[i % periodo] + buf[(i + 1) % periodo])
    return salida

def mezcla(*partes):
    n = max(len(p) for p in partes)
    s = np.zeros(n)
    for p in partes:
        s[:len(p)] += p
    return s

def retrasa(x, seg):
    return np.concatenate([np.zeros(int(SR * seg)), x])

def satura(x, k=2.0):
    return np.tanh(k * x) / np.tanh(k)

def guarda(nombre, x):
    x = np.asarray(x, dtype=np.float64)
    x -= np.mean(x)
    #fundido de 3 ms al principio y al final para que no haya chasquidos
    f = min(len(x) // 4, int(SR * 0.003))
    x[:f] *= np.linspace(0, 1, f)
    x[-f:] *= np.linspace(1, 0, f)
    x = x / (np.max(np.abs(x)) + 1e-9)
    ganancia = min(SONORIDAD - sonoridad_movil(x), GANANCIA_MAX_DB)
    x = limita(x * 10 ** (ganancia / 20))
    wavfile.write(os.path.join(DESTINO, nombre + ".wav"), SR, (x * 32767).astype(np.int16))
    print(f"{nombre:22s} {len(x) / SR:5.2f} s  sonoridad {sonoridad_movil(x):6.1f} dB")

def sonoridad_movil(x):
    """RMS (dB) de los 100 ms más fuertes de lo que suena en un altavoz de móvil (>900 Hz)"""
    y = filtro(x, "highpass", 900)
    v = int(SR * 0.1)
    if len(y) <= v:
        return 10 * np.log10(np.sum(y ** 2) / v + 1e-12)
    energia = np.convolve(y ** 2, np.ones(v) / v, mode="valid")
    return 10 * np.log10(np.max(energia) + 1e-12)

def limita(x, techo=10 ** (-1 / 20)):
    """limitador suave: por debajo del 70 % del techo no toca nada"""
    rodilla = techo * 0.7
    y = x.copy()
    m = np.abs(x) > rodilla
    exceso = np.abs(x[m]) - rodilla
    y[m] = np.sign(x[m]) * (rodilla + (techo - rodilla) * np.tanh(exceso / (techo - rodilla)))
    return y


# ---------- partida ----------

def disparo(var):
    """arco: chasquido de la cuerda + silbido de la flecha al salir"""
    f = [118, 128, 108][var]
    dur = 0.32
    golpe = filtro(ruido(0.012), "bandpass", [1500, 6000]) * env(0.012, 0.0005, curva=6)
    zumbido = cuerda(f, dur, 0.6) * env(dur, 0.001, curva=7) * 0.7
    zumbido = filtro(zumbido, "lowpass", 2500)
    silbido = filtro_barrido(ruido(0.16), 4500, 1200, "lowpass") * env(0.16, 0.02, curva=5)
    silbido = filtro(silbido, "highpass", 700) * 0.55
    return mezcla(golpe, zumbido, retrasa(silbido, 0.008))

def impacto(var):
    """flecha que se clava: golpe seco y grave"""
    dur = 0.14
    grave = tono([150, 135, 165][var], 55, dur) * env(dur, 0.001, curva=7)
    seco = filtro(ruido(0.05), "bandpass", [400, 2200]) * env(0.05, 0.0005, curva=8) * 0.8
    #el "zas" de la flecha al clavarse: lo que se oye en el altavoz del móvil
    zas = filtro(ruido(0.045), "bandpass", [1200, 4500]) * env(0.045, 0.0005, curva=7) * 0.9
    chasquido = filtro(ruido(0.008), "highpass", 3000) * env(0.008, 0.0003, curva=5) * 0.5
    return mezcla(grave * 0.35, seco * 0.8, zas, chasquido)

def muerte(var):
    """enemigo que cae: soplo descendente con golpe grave"""
    dur = 0.32
    soplo = filtro_barrido(ruido(dur), [2400, 1800][var], 250) * env(dur, 0.004, curva=4)
    golpe = tono(110, 40, 0.2) * env(0.2, 0.002, curva=6) * 0.9
    return mezcla(soplo * 0.8, golpe)

def moneda():
    """dos notas de campana agudas"""
    a = campana(1568, 0.07, 10) * 0.7
    b = campana(2093, 0.35, 7)
    return mezcla(a, retrasa(b, 0.055))

def puerta():
    """mejora: arpegio ascendente brillante"""
    notas = [523, 659, 784, 1047, 1319]
    s = np.zeros(int(SR * 0.7))
    for i, f in enumerate(notas):
        nota = (tono(f, f, 0.35, "tri") * 0.6 + campana(f * 2, 0.35, 8) * 0.3) * env(0.35, 0.003, curva=5)
        s = mezcla(s, retrasa(nota, i * 0.055))
    brillo = filtro(ruido(0.5), "highpass", 6000) * env(0.5, 0.15, curva=4) * 0.15
    return mezcla(s, retrasa(brillo, 0.1))

def daño():
    """golpe al jugador: impacto grave sucio"""
    dur = 0.3
    grave = tono(95, 38, dur) * env(dur, 0.001, curva=6)
    crujido = satura(filtro(ruido(0.12), "bandpass", [600, 3500]) * env(0.12, 0.001, curva=6), 3) * 0.7
    queja = filtro(tono(260, 150, 0.18, "saw"), "lowpass", 1200) * env(0.18, 0.01, curva=4) * 0.35
    return mezcla(grave * 0.5, crujido, queja)

def muerte_jugador():
    """tono que se hunde con vibrato y golpe final"""
    dur = 1.1
    tt = t(dur)
    f = 660 * (165 / 660) ** (tt / dur) * (1 + 0.03 * np.sin(2 * np.pi * 7 * tt))
    fase = 2 * np.pi * np.cumsum(f) / SR
    #diente de sierra suavizado: sus armónicos llevan el tono al altavoz del móvil
    voz = filtro(2 * ((fase / (2 * np.pi)) % 1) - 1, "lowpass", 3500)
    voz *= env(dur, 0.01, curva=2.5)
    golpe = tono(90, 35, 0.4) * env(0.4, 0.001, curva=5)
    return mezcla(voz * 0.7, retrasa(golpe, 0.0) * 0.8, retrasa(daño() * 0.5, 0.0))

def explosion(var):
    """estallido: ruido marrón con filtro que se cierra y subgrave"""
    dur = [0.8, 0.7][var]
    cuerpo = filtro_barrido(ruido_marron(dur) + 0.3 * ruido(dur), 4000, 150) * env(dur, 0.003, curva=4.5)
    sub = tono(70, 28, dur) * env(dur, 0.002, curva=5) * 0.9
    chasquido = filtro(ruido(0.03), "highpass", 1500) * env(0.03, 0.0005, curva=5) * 0.6
    chisporroteo = filtro(ruido(dur), "bandpass", [1200, 5000]) * env(dur, 0.002, curva=7) * 0.35
    return satura(mezcla(cuerpo, sub, chasquido, chisporroteo), 1.8)

def rayo():
    """chispazo eléctrico: crepitar entrecortado y zumbido"""
    dur = 0.35
    tt = t(dur)
    puerta_aleatoria = (rng.uniform(0, 1, len(tt) // 400 + 1) > 0.45).repeat(400)[:len(tt)]
    crepita = filtro(ruido(dur), "bandpass", [1800, 8000]) * puerta_aleatoria
    zumbido = filtro(tono(110, 95, dur, "saw") * (0.5 + 0.5 * np.sign(np.sin(2 * np.pi * 50 * tt))), "lowpass", 3000)
    golpe = filtro(ruido(0.02), "highpass", 2000) * env(0.02, 0.0003, curva=4)
    return mezcla((crepita * 0.8 + zumbido * 0.5) * env(dur, 0.002, curva=4), golpe)

def bola_fuego():
    """lanzamiento de fuego: soplido que crece y ruge"""
    dur = 0.6
    soplo = filtro_barrido(ruido(dur), 400, 2200, "lowpass") * env(dur, 0.12, curva=3.5)
    rugido = filtro(satura(tono(75, 60, dur, "saw") * 0.8 + ruido_marron(dur) * 0.5, 2), "lowpass", 900)
    rugido *= env(dur, 0.06, curva=3)
    return mezcla(soplo * 0.8, rugido * 0.6)

def magia():
    """conjuro: barrido de tono con brillo"""
    dur = 0.4
    tt = t(dur)
    zap = tono(1400, 300, dur) * (1 + 0.5 * np.sin(2 * np.pi * 30 * tt)) * env(dur, 0.003, curva=4)
    brillo = filtro(ruido(dur), "highpass", 5000) * env(dur, 0.01, curva=6) * 0.25
    return mezcla(zap * 0.6, brillo, tono(700, 150, dur, "tri") * env(dur, 0.003, curva=5) * 0.4)

def burbujas(n, dur, fmin, fmax):
    s = np.zeros(int(SR * dur))
    for _ in range(n):
        d = rng.uniform(0.03, 0.07)
        f = rng.uniform(fmin, fmax)
        b = tono(f, f * 1.8, d) * env(d, 0.002, curva=5)
        s = mezcla(s, retrasa(b, rng.uniform(0, dur - d)))
    return s[:int(SR * dur)]

def acido():
    """escupitajo: soplo húmedo con burbujas"""
    dur = 0.35
    escupe = filtro(ruido(0.12), "bandpass", [700, 2600]) * env(0.12, 0.004, curva=5)
    return mezcla(escupe, burbujas(7, dur, 300, 900) * 0.6)

def salpicadura():
    """ácido que cae: chapoteo y burbujeo"""
    dur = 0.5
    chapoteo = filtro_barrido(ruido(dur), 3500, 400) * env(dur, 0.002, curva=5)
    return mezcla(chapoteo * 0.8, burbujas(12, dur, 250, 1100) * 0.5)

def piedra():
    """lanzamiento pesado: soplido grave"""
    dur = 0.45
    soplo = filtro(filtro_barrido(ruido(dur), 500, 2000, "lowpass"), "highpass", 150)
    return soplo * env(dur, 0.15, curva=4)

def golpe_piedra():
    """roca que cae: retumbo y crujido"""
    dur = 0.55
    retumbo = tono(65, 30, dur) * env(dur, 0.001, curva=5)
    tierra = filtro(ruido_marron(dur), "lowpass", 600) * env(dur, 0.002, curva=5) * 0.8
    crujido = filtro(ruido(0.06), "bandpass", [800, 3500]) * env(0.06, 0.0005, curva=6) * 0.7
    #grava que salta: crepitar entrecortado
    salto = (rng.uniform(0, 1, int(SR * dur) // 300 + 1) > 0.6).repeat(300)[:int(SR * dur)]
    grava = filtro(ruido(dur), "bandpass", [1000, 4500]) * salto * env(dur, 0.002, curva=6) * 0.4
    return satura(mezcla(retumbo * 0.45, tierra * 0.5, crujido, grava * 1.3), 1.5)

def impacto_magia():
    """estallido mágico: destello agudo con campanas"""
    dur = 0.6
    destello = filtro(ruido(0.25), "highpass", 2500) * env(0.25, 0.001, curva=6) * 0.5
    golpe = tono(220, 70, 0.25) * env(0.25, 0.001, curva=6) * 0.7
    tintineo = mezcla(campana(1760, dur, 5) * 0.3, retrasa(campana(2349, dur - 0.04, 6) * 0.25, 0.04))
    return mezcla(destello, golpe, tintineo)

def rugido(dur=1.6, f_ini=85, f_max=110, f_fin=60, semilla=0):
    """rugido de dragón: diente de sierra áspero por formantes, con temblor"""
    tt = t(dur)
    k = tt / dur
    contorno = np.where(k < 0.3, f_ini + (f_max - f_ini) * k / 0.3, f_max + (f_fin - f_max) * (k - 0.3) / 0.7)
    temblor = 1 + 0.06 * filtro(rng.uniform(-1, 1, len(tt)), "lowpass", 25) * 8
    fase = 2 * np.pi * np.cumsum(contorno * temblor) / SR
    voz = 2 * ((fase / (2 * np.pi)) % 1) - 1
    fuente = voz * 0.7 + ruido(dur) * 0.45
    formantes = (filtro(fuente, "bandpass", [380, 750]) * 1.0
                 + filtro(fuente, "bandpass", [900, 1400]) * 0.7
                 + filtro(fuente, "bandpass", [2200, 3000]) * 0.35)
    forma = np.minimum(1, k / 0.12) * np.exp(-2.2 * np.maximum(0, k - 0.45))
    sub = tono(f_ini * 0.5, f_fin * 0.5, dur) * forma * 0.5
    return satura(formantes * forma * 1.5 + sub, 2.5)

def muerte_boss():
    """rugido largo que se apaga y derrumbe"""
    grito = rugido(2.4, 120, 140, 45)
    caida = explosion(0) * 0.8
    return mezcla(grito, retrasa(caida, 1.6))


# ---------- interfaz ----------

def toque(f, dur=0.09):
    """toque de madera: tono que baja un poco, su octava y un chasquido de ataque"""
    return mezcla(tono(f, f * 0.85, dur) * env(dur, 0.0005, curva=8),
                  tono(f * 2, f * 1.7, dur) * env(dur, 0.0005, curva=11) * 0.45,
                  filtro(ruido(0.01), "bandpass", [2000, 7000]) * env(0.01, 0.0002, curva=4) * 0.5)

def click():
    """botón: toque corto y brillante (1,5-4 kHz: el altavoz del móvil no da graves)"""
    return toque(1800)

def atras():
    """volver: dos toques descendentes"""
    return mezcla(toque(1700, 0.07), retrasa(toque(1250), 0.06))

def compra():
    """compra: monedas que caen y campanilla"""
    s = np.zeros(int(SR * 0.7))
    for i, f in enumerate([1568, 1760, 2093, 1976]):
        s = mezcla(s, retrasa(campana(f, 0.25, 9) * 0.5, i * 0.045 + rng.uniform(0, 0.01)))
    return mezcla(s, retrasa(campana(2637, 0.5, 5) * 0.7, 0.2))

def error():
    """sin oro: zumbido doble"""
    zumbido = filtro(tono(196, 196, 0.12, "sq") + tono(208, 208, 0.12, "sq"), "lowpass", 3500) * env(0.12, 0.003, curva=2)
    return mezcla(zumbido * 0.5, retrasa(zumbido * 0.5, 0.15))

def logro():
    """logro: arpegio de campanas y brillo"""
    s = np.zeros(int(SR * 1.3))
    for i, f in enumerate([784, 988, 1175, 1568]):
        s = mezcla(s, retrasa(campana(f, 0.9, 3.5) * 0.5 + tono(f, f, 0.9, "tri") * env(0.9, 0.005, curva=4) * 0.3, i * 0.09))
    brillo = filtro(ruido(0.9), "highpass", 7000) * env(0.9, 0.3, curva=4) * 0.12
    return mezcla(s, retrasa(brillo, 0.25))


def main():
    os.makedirs(DESTINO, exist_ok=True)
    for v in range(3):
        guarda(f"disparo_{v + 1}", disparo(v))
        guarda(f"impacto_{v + 1}", impacto(v))
    for v in range(2):
        guarda(f"muerte_{v + 1}", muerte(v))
        guarda(f"explosion_{v + 1}", explosion(v))
    for nombre, f in [("moneda", moneda), ("puerta", puerta), ("herido", daño), ("muerte_jugador", muerte_jugador),
                      ("rayo", rayo), ("bola_fuego", bola_fuego), ("magia", magia), ("acido", acido),
                      ("salpicadura", salpicadura), ("piedra", piedra), ("golpe_piedra", golpe_piedra),
                      ("impacto_magia", impacto_magia), ("rugido", rugido), ("muerte_boss", muerte_boss),
                      ("click", click), ("atras", atras), ("compra", compra), ("error", error), ("logro", logro)]:
        guarda(nombre, f())


if __name__ == "__main__":
    main()
