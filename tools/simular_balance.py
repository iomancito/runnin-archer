# Simula campañas completas de Running Archer (de 0 de oro a superar Hell) para comparar
# variantes de balance antes de tocar el juego. Es un modelo aproximado: sirve para comparar
# variantes entre sí, no como números absolutos.
#
# Copia a mano los números de scripts/balance.gd y el diseño de scripts/niveles.gd: si cambian
# allí, hay que cambiarlos aquí (ENEMIGOS, NIVELES, ARCOS, LANZADOR y los valores por defecto
# de Parametros).
#
# Modelo:
#  - Reproduce MapGenerator: filas de enemigos, hordas y columnas, puertas y mini jefes.
#  - El bot dispara por orden de llegada a lo que le da tiempo a matar (ventana = alcance /
#    velocidad relativa) y esquiva el resto, con una probabilidad de chocar.
#  - Columnas y hordas son un objetivo conjunto: el daño que entra se multiplica por la
#    habilidad del arco (perforar, explosión, cadena); si limpia menos de la mitad, las esquiva.
#  - Los lanzadores (troll, cría, escupidor, mago) disparan según Balance.LANZADOR de la
#    dificultad mientras siguen vivos; cada disparo acierta con una probabilidad.
#  - Puertas: vida si va por debajo del 50 %, si no lo que más DPS da.
#  - Boss: impactos al azar (Poisson) con la tasa medida con un bot que esquiva.
#  - Entre partidas compra el arco nuevo al desbloquearlo y luego, con la estrategia "tienda",
#    siempre el nivel más barato (6 mejoras de la tienda y el nivel del arco); con "arco", sube
#    antes el arco si le llega el oro. No simula Gold Bonus, Run Speed ni Arrow Speed.
#  - Cada arco se desbloquea al superar su dificultad; arco_logro / logro / logro_dif prueban a
#    desbloquear uno con un logro de otra dificultad: "mapa" (superar un mapa), "sin_daño"
#    (Untouchable: un mapa sin recibir daño) o "exterminador" (Exterminator: matando a todos).
#  - Jugador "bueno": choca con el 5 % de lo que esquiva y le aciertan el 10 % de los disparos;
#    "medio": 12 %, 25 % y el doble de impactos del boss.
#
# Uso:
#   python3 tools/simular_balance.py                          # balance actual, 40 campañas
#   python3 tools/simular_balance.py -n 100 --seed 3
#   python3 tools/simular_balance.py --set g_vida=1.5 --set crec=1.5   # una variante
#   python3 tools/simular_balance.py --set estrategia=arco --set logro=sin_daño   # Dragonbone con Untouchable en Hard
#
# Salida por dificultad: partidas hasta superarla (mediana y p10-p90), reparto de muertes en
# los mapas 1/2/3 (sobre 9), oro gastado en la tienda y arco más habitual al terminarla.
# Después, por dificultad: % de mapas superados sin daño y matando a todos, y en qué partida de
# su dificultad se desbloquea el arco de arco_logro.

import argparse, math, random
from collections import Counter

#vida, daño al chocar, oro (Balance.ENEMIGOS)
ENEMIGOS = {"goblin": (2, 2, 1), "orc": (5, 3, 2), "troll": (14, 5, 4), "ogre": (30, 8, 10), "whelp": (7, 3, 3),
            "zombie": (4, 2, 1), "spitter": (6, 3, 3), "brute": (25, 6, 8), "skeleton": (3, 2, 1),
            "skeleton_mage": (6, 3, 3), "reaper": (12, 5, 4), "death_knight": (32, 8, 10)}
#m/s hacia el player (los zombis normales: 0, 1 o 2 al azar)
VEL = {"skeleton": 1.6, "brute": 1.0, "reaper": 0.8}
#daño del proyectil (Balance.PROYECTIL_DAÑO)
PROYECTIL_DAÑO = {"troll": 4, "whelp": 3, "skeleton_mage": 4, "spitter": 3}
#Balance.LANZADOR (aviso no entra: lo resume la probabilidad de acierto)
LANZADOR = {"easy": dict(distancia=18.0, recarga=3.0, disparos=2), "medium": dict(distancia=20.0, recarga=2.4, disparos=3),
            "hard": dict(distancia=21.0, recarga=2.2, disparos=3), "hell": dict(distancia=21.0, recarga=2.1, disparos=3)}
ORDEN = ["easy", "medium", "hard", "hell"]
#impactos del boss por segundo con el bot que esquiva (docs/balance.md: 0-1, 1-2, 2-3, 3-6 en 15 s)
BOSS_LAMBDA = {"easy": 0.5 / 15, "medium": 1.5 / 15, "hard": 2.5 / 15, "hell": 4.5 / 15}
CARRILES = [-4.0, -2.0, 0.0, 2.0, 4.0]
ZONA_LIBRE, SEP_MIN = 7.0, 6.0
HORDA_ESPACIO = (1.3, 1.6)
COLUMNA_ESPACIO = 1.8

#Niveles.MAPAS
NIVELES = {
    1: dict(largo=1000.0, inicio=25.0, fin_libre=45.0, separacion=(20.0, 10.0), por_fila=(1, 3),
            tipos={"goblin": (1.0, 0.15, 0.0), "orc": (0.2, 1.0, 0.1), "troll": (0.3, 0.6, 0.45), "whelp": (0.25, 0.5, 0.6)},
            jefe="ogre", jefes_z=[250.0, 500.0, 750.0], puertas=[90.0, 175.0, 330.0, 420.0, 580.0, 670.0, 830.0, 910.0],
            hordas=dict(tipo="goblin", separacion=(160.0, 90.0), desde=0.12, carriles=(2, 3), filas=(3, 5)),
            columnas=dict(separacion=(120.0, 70.0), desde=0.1, largo=(3, 5))),
    2: dict(largo=1000.0, inicio=25.0, fin_libre=45.0, separacion=(14.0, 7.0), por_fila=(1, 3),
            tipos={"zombie": (1.0, 1.0, 0.0), "spitter": (0.15, 0.35, 0.15)},
            jefe="brute", jefes_z=[300.0, 600.0, 850.0],
            puertas=[80.0, 170.0, 250.0, 380.0, 470.0, 540.0, 680.0, 770.0, 920.0],
            hordas=dict(tipo="zombie", separacion=(150.0, 80.0), desde=0.1, carriles=(2, 3), filas=(3, 5)),
            columnas=dict(separacion=(110.0, 65.0), desde=0.1, largo=(3, 5))),
    3: dict(largo=1000.0, inicio=25.0, fin_libre=45.0, separacion=(16.0, 8.0), por_fila=(1, 3),
            tipos={"skeleton": (1.0, 0.4, 0.0), "skeleton_mage": (0.2, 0.5, 0.1), "reaper": (0.15, 1.0, 0.3)},
            jefe="death_knight", jefes_z=[200.0, 400.0, 600.0, 800.0],
            puertas=[90.0, 160.0, 300.0, 360.0, 500.0, 560.0, 700.0, 760.0, 900.0],
            hordas=dict(tipo="skeleton", separacion=(140.0, 80.0), desde=0.08, carriles=(2, 3), filas=(4, 5)),
            columnas=dict(separacion=(100.0, 60.0), desde=0.08, largo=(3, 5))),
}

#Balance.ARCOS: cada valor es [nivel 1, suma por nivel]
ARCOS = {
    "thorn": dict(dif="easy", coste=(150, 1.6), daño=(1.10, 0.05), perfora=(1, 1)),
    "sunfire": dict(dif="medium", coste=(400, 1.6), daño=(1.20, 0.05), radio=(1.5, 0.25), exp=(0.4, 0.15)),
    "storm": dict(dif="hard", coste=(1000, 1.6), daño=(1.30, 0.05), cad=(1.15, 0), saltos=(2, 1), cadena=(0.5, 0.1)),
    "dragon": dict(dif="hell", coste=(2500, 1.6), daño=(2.0, 0.25), cad=(1.2, 0.05), perfora=(2, 1),
                   radio=(2.0, 0.25), exp=(0.6, 0.1), quem=(0.5, 0.15), boss=(0.5, 0.25)),
}
#tiempo límite de Swift Hunter / Perfect Hunt (Balance.LOGRO_TIEMPO) y duración de la quemadura
LOGRO_TIEMPO = {"easy": 240.0, "medium": 240.0, "hard": 250.0, "hell": 260.0}
QUEMADURA_SEG = 3.0

#stats base del player (Progreso.BASE_STATS)
BASE = dict(dmg=1, rate=1.0, arr=1, hp=10, rng=10, side=150, speed=200)
#m/s de la flecha (f_velocidad 600 / 60; no se simula Arrow Speed)
VEL_FLECHA = 10.0

SKILLS = {"bueno": (0.05, 0.10, 1.0), "medio": (0.12, 0.25, 2.0)}


class Parametros:
    """Lo que se puede variar. Por defecto, el balance actual del juego."""
    def __init__(self, **kw):
        #etapas: multiplicador = base * crecimiento^etapa, etapa = dificultad * paso_dif + mapa - 1
        self.g_vida, self.g_daño, self.g_oro = 1.7, 1.2, 1.15
        self.base_vida, self.base_daño, self.base_oro = 0.6, 0.5, 0.6
        self.paso_dif = 2            #ETAPAS_POR_DIFICULTAD
        self.vida_m = 1 / 400        #VIDA_POR_METRO
        self.daño_k = 0.5            #DAÑO_POR_METRO = VIDA_POR_METRO * daño_k
        self.crec = 1.6              #CRECIMIENTO_COSTES de la tienda
        self.niveles_tienda = 10     #niveles de Damage y Fire Rate
        self.boss_vida = 350
        self.densidad = {"easy": 0.75, "medium": 1.0, "hard": 1.25, "hell": 1.5}
        self.hordas = {"easy": 0.0, "medium": 0.6, "hard": 1.0, "hell": 1.6}
        self.columnas = {"easy": 0.0, "medium": 1.0, "hard": 1.0, "hell": 1.2}
        self.arcos = True
        self.estrategia = "tienda"          #"tienda" (lo más barato) o "arco" (antes el arco)
        #arco que se desbloquea con un logro de logro_dif en vez de al superar su dificultad
        self.arco_logro = "dragon"
        self.logro = "completar"            #"completar" (como ahora) o "mapa", "sin_daño", "exterminador"
        self.logro_dif = "hard"
        self.__dict__.update(kw)

    def mult(self, d, m):
        e = ORDEN.index(d) * self.paso_dif + m - 1
        return self.base_vida * self.g_vida ** e, self.base_daño * self.g_daño ** e, self.base_oro * self.g_oro ** e


def lerp(a, b, t): return a + (b - a) * t
def cerca(z, res): return any(abs(z - r) < ZONA_LIBRE for r in res)
def costes(b, c, n=10): return [int(round(b * c ** i)) for i in range(n)]

def av(arco, k, n, neutro=0.0):
    if not arco or k not in ARCOS[arco]:
        return neutro
    v = ARCOS[arco][k]
    return v[0] + v[1] * (n - 1)

def elige_tipo(tipos, t):
    pesos = {k: (0.0 if t < d[2] else lerp(d[0], d[1], t)) for k, d in tipos.items()}
    r = random.random() * sum(pesos.values())
    for k, p in pesos.items():
        r -= p
        if r <= 0:
            return k
    return next(iter(tipos))

def generar(cfg, d, par):
    """Eventos por z: ("fila", z, [(tipo, horda)]), ("grupo", z, tipo, n, clase, fondo) o ("puerta", z)."""
    ev = []
    res = list(cfg["puertas"]) + list(cfg["jefes_z"])
    for z in cfg["jefes_z"]:
        ev.append(("fila", z, [(cfg["jefe"], False)]))
    largo = cfg["largo"]
    fin = largo - cfg["fin_libre"]
    tramos = []

    def formaciones(clave, freq, crear):
        h = cfg[clave]
        z = max(cfg["inicio"], h["desde"] * largo)
        while z < fin:
            t = z / largo
            r = crear(t)
            fondo = r[-1]
            libre = not any(a - ZONA_LIBRE < z < b + ZONA_LIBRE or a - ZONA_LIBRE < z + fondo < b + ZONA_LIBRE for a, b in tramos)
            if z + fondo < fin and not cerca(z, res) and not cerca(z + fondo, res) and libre:
                ev.append(("grupo", z) + r)
                tramos.append((z, z + fondo))
                z += fondo
            z += lerp(*h["separacion"], t) / freq * random.uniform(0.85, 1.15)

    if par.hordas[d] > 0:
        def horda(t):
            h = cfg["hordas"]
            carr = round(lerp(*h["carriles"], t))
            filas = round(lerp(*h["filas"], t))
            por_fila = int(((carr - 1) * 2.0 + 1.2) / HORDA_ESPACIO[0]) + 1
            return (h["tipo"], filas * por_fila, "horda", (filas - 1) * HORDA_ESPACIO[1])
        formaciones("hordas", par.hordas[d], horda)
    if par.columnas[d] > 0:
        def columna(t):
            n = max(round(lerp(*cfg["columnas"]["largo"], t)), 2)
            return (elige_tipo(cfg["tipos"], t), n, "columna", (n - 1) * COLUMNA_ESPACIO)
        formaciones("columnas", par.columnas[d], columna)
    z = cfg["inicio"]
    while z < fin:
        t = z / largo
        if not cerca(z, res) and not any(a - ZONA_LIBRE < z < b + ZONA_LIBRE for a, b in tramos):
            n = random.randint(1, max(1, min(3, round(lerp(*cfg["por_fila"], t)))))
            ev.append(("fila", z, [(elige_tipo(cfg["tipos"], t), False) for _ in range(n)]))
        z += max(lerp(*cfg["separacion"], t) / par.densidad[d] * random.uniform(0.85, 1.15), SEP_MIN)
    for zp in cfg["puertas"]:
        ev.append(("puerta", zp))
    ev.sort(key=lambda e: e[1])
    return ev

def jugar_mapa(m, d, st, par, skill):
    """Devuelve dict: ganado, oro, z (de la muerte), causas (daño recibido por causa), todos (ha
    matado a todos) y tiempo (s hasta matar al boss)."""
    mv, md, mo = par.mult(d, m)
    p_err, p_proy, boss_mult = skill
    s = dict(st)
    vida = vida_max = s["hp"]
    oro = 0
    arco, an = s.get("arco", ""), s.get("arco_nivel", 0)
    vp = s["speed"] / 60.0
    cursor = 0.0
    causas = Counter()
    lado = 150 / s["side"]
    lz = LANZADOR[d]
    #segundos para pasar al carril de al lado (2 m)
    cambio = 2.0 / (s["side"] / 60.0)
    todos = True  #ha matado a todos (logro Exterminator)
    escapados = Counter()  #enemigos que no ha matado, por tipo y formación

    def daño_flecha(): return max(1, round(s["dmg"] * av(arco, "daño", an, 1.0)))
    def cadencia(): return s["rate"] * av(arco, "cad", an, 1.0)

    def mult_grupo(clase, n):
        if arco == "thorn":
            return min(1 + av(arco, "perfora", an), n)
        if arco == "sunfire":
            r = av(arco, "radio", an)
            vecinos = (3 if r < 1.8 else 5) if clase == "horda" else (2 if r >= COLUMNA_ESPACIO else 0)
            return 1 + min(vecinos, n - 1) * av(arco, "exp", an)
        if arco == "storm":
            return 1 + min(av(arco, "saltos", an), n - 1) * av(arco, "cadena", an)
        if arco == "dragon":
            #atraviesa, y cada impacto explota y prende fuego a los vecinos (radio en la rejilla de
            #la horda o hacia atrás en la columna); la quemadura no se acumula: daño * quem por segundo
            r = av(arco, "radio", an)
            if clase == "horda":
                vecinos = round(math.pi * r * r / (HORDA_ESPACIO[0] * HORDA_ESPACIO[1])) - 1
            else:
                vecinos = int(r // COLUMNA_ESPACIO)
            vecinos = min(n - 1, max(vecinos, 0))
            flechas = cadencia() * daño_flecha() * s["arr"]
            quema = daño_flecha() * av(arco, "quem", an) * (1 + vecinos) / flechas
            return min(1 + av(arco, "perfora", an), n) + vecinos * av(arco, "exp", an) + quema
        return 1.0

    def mult_fila(n):
        if arco == "storm":
            return 1 + min(av(arco, "saltos", an), n) * av(arco, "cadena", an)
        if arco == "sunfire" and av(arco, "radio", an) >= 2.0 and n > 1:
            return 1 + av(arco, "exp", an) * 0.5
        if arco == "dragon":
            return 1 + av(arco, "quem", an) / (cadencia() * s["arr"])
        return 1.0

    def explosion_fila():
        """Fracción del daño que la explosión hace a los compañeros de fila (0 si no llega al carril
        de al lado, a 2 m)."""
        if arco in ("sunfire", "dragon") and av(arco, "radio", an) >= 2.0:
            return av(arco, "exp", an)
        return 0.0

    def vida_e(tipo, z, horda): return math.ceil(ENEMIGOS[tipo][0] * (1 + z * par.vida_m) * mv * (0.5 if horda else 1))
    def daño_e(tipo, z, horda): return math.ceil(ENEMIGOS[tipo][1] * (1 + z * par.vida_m * par.daño_k) * md * (0.5 if horda else 1))
    def oro_e(tipo, horda): return max(1, round(ENEMIGOS[tipo][2] * mo * (0.5 if horda else 1)))

    def disparos(tipo, t_llega, t_muerte, ve):
        nonlocal vida
        if tipo not in PROYECTIL_DAÑO:
            return
        ts = t_llega - lz["distancia"] / (vp + ve)
        fin = t_llega - 2.0 / (vp + ve)
        for _ in range(lz["disparos"]):
            if ts >= t_muerte or ts >= fin:
                break
            if random.random() < p_proy * lado:
                dd = math.ceil(PROYECTIL_DAÑO[tipo] * md)
                vida -= dd
                causas["proyectil"] += dd
            ts += lz["recarga"]

    def puerta():
        nonlocal vida, vida_max
        ops = set(random.sample(["dmg", "rate", "arr", "rng", "side", "hp"], 2))
        if vida < 0.5 * vida_max and "hp" in ops:
            e = "hp"
        else:
            e, mejor = None, s["dmg"] * s["rate"] * s["arr"]
            for o in ops:
                v = {"dmg": (s["dmg"] + 1) * s["rate"] * s["arr"], "rate": s["dmg"] * (s["rate"] + .15) * s["arr"],
                     "arr": s["dmg"] * s["rate"] * min(s["arr"] + 1, 7)}.get(o, 0)
                if v > mejor:
                    e, mejor = o, v
            e = e or ("hp" if "hp" in ops else ("rng" if "rng" in ops else next(iter(ops))))
        if e == "dmg": s["dmg"] += 1
        elif e == "rate": s["rate"] += .15
        elif e == "arr": s["arr"] = min(s["arr"] + 1, 7)
        elif e == "rng": s["rng"] += 3
        elif e == "side": s["side"] += 15
        else:
            vida_max += 10
            vida += 10

    for ev in generar(NIVELES[m], d, par):
        if ev[0] == "puerta":
            puerta()
            continue
        z = ev[1]
        if ev[0] == "fila" and len(ev[2]) > 1 and explosion_fila() > 0:
            #la explosión llega al carril de al lado: disparando al del medio se daña a toda la fila
            tipos = [t for t, _ in ev[2]]
            n = len(tipos)
            ve = max(VEL.get(t, 0.0) for t in tipos)
            t_llega = (z - 40.0) / vp + 40.0 / (vp + ve)
            entra = t_llega - s["rng"] / (vp + ve)
            ini = max(cursor, entra)
            vuelo = s["rng"] / 2 / VEL_FLECHA
            #el más duro marca cuánto hay que disparar: le llega el golpe directo o la explosión
            vida_max_fila = max(vida_e(t, z, False) for t in tipos)
            golpe = daño_flecha() * s["arr"] * mult_fila(n) * min(1.0, explosion_fila() + 1.0 / n)
            t_disparo = (math.ceil(vida_max_fila / golpe) - 1) / cadencia()
            if ini + t_disparo + vuelo <= t_llega - 0.1:
                cursor = ini + t_disparo
                for t in tipos:
                    oro += oro_e(t, False)
                    disparos(t, t_llega, cursor, ve)
            else:
                todos = False
                for t in tipos:
                    escapados[t] += 1
                    disparos(t, t_llega, t_llega, ve)
                if random.random() < p_err * lado:
                    dd = daño_e(tipos[0], z, False)
                    vida -= dd
                    causas["choque"] += dd
            if vida <= 0:
                return dict(ganado=False, oro=oro, z=z, causas=causas, todos=False, tiempo=0.0, escapados=escapados)
        elif ev[0] == "fila":
            mf = mult_fila(len(ev[2]))
            objetivos = 0
            for tipo, horda in ev[2]:
                ve = VEL.get(tipo, 0.0)
                if tipo == "zombie":
                    ve = random.choice([0.0, 1.0, 2.0, 2.0])
                #aparecen a 40 m (cámara) y desde ahí se acercan a vp + ve
                t_llega = (z - 40.0) / vp + 40.0 / (vp + ve)
                entra = t_llega - s["rng"] / (vp + ve)
                #tiempo disparando (ocupa al player) y vuelo de la última flecha (no lo ocupa);
                #entre objetivos de la misma fila hay que cambiar de carril
                t_disparo = (math.ceil(vida_e(tipo, z, horda) / (daño_flecha() * s["arr"] * mf)) - 1) / cadencia()
                vuelo = s["rng"] / 2 / VEL_FLECHA
                ini = max(cursor + (cambio if objetivos else 0.0), entra)
                if ini + t_disparo + vuelo <= t_llega - 0.1:
                    objetivos += 1
                    cursor = ini + t_disparo
                    oro += oro_e(tipo, horda)
                    disparos(tipo, t_llega, cursor, ve)
                else:
                    todos = False
                    escapados[tipo] += 1
                    disparos(tipo, t_llega, t_llega, ve)
                    if random.random() < p_err * lado:
                        dd = daño_e(tipo, z, horda)
                        vida -= dd
                        causas["choque"] += dd
                if vida <= 0:
                    return dict(ganado=False, oro=oro, z=z, causas=causas, todos=False, tiempo=0.0, escapados=escapados)
        else:
            _, _, tipo, n, clase, fondo = ev
            horda = clase == "horda"
            ve = 1.0 if tipo == "zombie" else VEL.get(tipo, 0.0)
            t_llega = (z - 40.0) / vp + 40.0 / (vp + ve)
            entra = t_llega - s["rng"] / (vp + ve)
            fin = t_llega + fondo / (vp + ve)
            ini = max(cursor, entra)
            #las flechas sobrantes siguen al siguiente: cuenta el daño total que entra en el grupo;
            #el player queda ocupado solo hasta matarlos a todos (o hasta que pasan)
            dps_grupo = cadencia() * daño_flecha() * s["arr"] * mult_grupo(clase, n)
            hace_falta = n * vida_e(tipo, z, horda) / dps_grupo
            ventana = max(0.0, fin - ini - 0.1)
            muertos = n if hace_falta <= ventana else min(n, int(ventana * dps_grupo // vida_e(tipo, z, horda)))
            if muertos < n:
                todos = False
                escapados[f"{tipo} ({clase})"] += n - muertos
            if muertos >= n / 2:
                cursor = ini + min(hace_falta, ventana)
                oro += muertos * oro_e(tipo, horda)
                if muertos < n and random.random() < min(1.0, p_err * 3 * lado):
                    dd = daño_e(tipo, z, horda)
                    vida -= dd
                    causas["grupo"] += dd
                for _ in range(muertos):
                    disparos(tipo, t_llega, ini + 0.5, ve)
            else:
                for _ in range(n):
                    disparos(tipo, t_llega, t_llega, ve)
                if random.random() < p_err * lado * (0.5 if horda else 1.0):
                    dd = daño_e(tipo, z, horda)
                    vida -= dd
                    causas["choque"] += dd
            if vida <= 0:
                return dict(ganado=False, oro=oro, z=z, causas=causas, todos=False, tiempo=0.0, escapados=escapados)
    #boss: lo que tarda en matarlo contra impactos al azar
    dps = daño_flecha() * s["arr"] * cadencia() * (1 + av(arco, "boss", an))
    if arco == "dragon":
        dps += daño_flecha() * av(arco, "quem", an)
    t_boss = par.boss_vida * mv / dps
    boss_d = math.ceil(3 * md)
    lam = BOSS_LAMBDA[d] * boss_mult * lado
    t = 0.0
    while True:
        t += random.expovariate(lam)
        if t >= t_boss:
            return dict(ganado=True, oro=oro + round(100 * mo), z=1000, causas=causas, todos=todos,
                        tiempo=NIVELES[m]["largo"] / vp + t_boss, escapados=escapados)
        vida -= boss_d
        causas["boss"] += boss_d
        if vida <= 0:
            return dict(ganado=False, oro=oro, z=1000, causas=causas, todos=False, tiempo=0.0, escapados=escapados)

def tienda(par):
    c, n = par.crec, par.niveles_tienda
    return {"damage": ("dmg", 1, costes(12, c, n)), "attack_speed": ("rate", 0.1, costes(12, c, n)),
            "arrow_number": ("arr", 1, [50, 170, 520, 1340]),
            "vida": ("hp", 5, costes(8, c)), "range": ("rng", 2, costes(8, c)), "dodge": ("side", 10, costes(6, c))}

def campaña(par, skill, max_partidas=80):
    T = tienda(par)
    niv = {k: 0 for k in T}
    oro, arco, an = 0, "", 0
    completadas, res = [], {}
    #arcos desbloqueados por logro antes de completar su dificultad
    por_logro = []
    for d in ORDEN:
        partidas, muertes = 0, Counter()
        mapas = sin_daño = exterminados = 0
        logro_en = 0
        while partidas < max_partidas:
            partidas += 1
            st = dict(BASE)
            for k, (stat, inc, _) in T.items():
                st[stat] += inc * niv[k]
            st["arco"], st["arco_nivel"] = arco, an
            ganada = True
            for m in (1, 2, 3):
                r = jugar_mapa(m, d, st, par, skill)
                ok, o, causas, todos = r["ganado"], r["oro"], r["causas"], r["todos"]
                oro += o
                if ok:
                    mapas += 1
                    limpio = sum(causas.values()) == 0
                    sin_daño += limpio
                    exterminados += todos
                    logro = {"mapa": True, "sin_daño": limpio, "exterminador": todos}.get(par.logro, False)
                    if d == par.logro_dif and logro and par.arco_logro not in por_logro:
                        por_logro.append(par.arco_logro)
                        logro_en = partidas
                if not ok:
                    muertes[m] += 1
                    ganada = False
                    break
            if ganada and d not in completadas:
                completadas.append(d)
            if par.arcos:
                disponibles = [a for a in ARCOS if (ARCOS[a]["dif"] in completadas and not (a == par.arco_logro and par.logro != "completar"))
                               or a in por_logro]
                if disponibles and disponibles[-1] != arco and ARCOS[disponibles[-1]]["coste"][0] <= oro:
                    arco, an = disponibles[-1], 1
                    oro -= ARCOS[arco]["coste"][0]
            while par.estrategia == "arco" and arco and an < 5:
                c = round(ARCOS[arco]["coste"][0] * ARCOS[arco]["coste"][1] ** an)
                if c > oro:
                    break
                oro -= c
                an += 1
            while True:
                opciones = [(T[k][2][niv[k]], k) for k in T if niv[k] < len(T[k][2])]
                if arco and an < 5:
                    opciones.append((round(ARCOS[arco]["coste"][0] * ARCOS[arco]["coste"][1] ** an), "arco"))
                if not opciones:
                    break
                c, k = min(opciones)
                if c > oro:
                    break
                oro -= c
                if k == "arco":
                    an += 1
                else:
                    niv[k] += 1
            if ganada:
                break
        gastado = sum(sum(T[k][2][:n]) for k, n in niv.items())
        if par.logro == "completar" and d == ARCOS[par.arco_logro]["dif"] and d in completadas:
            logro_en = partidas
        res[d] = dict(partidas=partidas, muertes=muertes, gastado=gastado, arco=f"{arco}{an}" if arco else "-",
                      mapas=mapas, sin_daño=sin_daño, exterminados=exterminados, logro_en=logro_en)
        if partidas >= max_partidas:
            break
    return res

def informe(nombre, par, n=40, seed=1):
    random.seed(seed)
    print(f"--- {nombre}")
    for sk_n, sk in SKILLS.items():
        campañas = [campaña(par, sk) for _ in range(n)]
        out = []
        for d in ORDEN:
            r = [x[d] for x in campañas if d in x]
            if len(r) < n * 0.5:
                out.append(f"{d}: no llega")
                continue
            p = sorted(x["partidas"] for x in r)
            mu = Counter()
            for x in r:
                mu.update(x["muertes"])
            tot = sum(mu.values()) or 1
            arc = Counter(x["arco"] for x in r).most_common(1)[0][0]
            out.append(f"{d} {p[len(p) // 2]:>2} ({p[len(p) // 10]}-{p[9 * len(p) // 10]}) "
                       f"muertes {'/'.join(str(round(mu[i] * 9 / tot)) for i in (1, 2, 3))} "
                       f"oro {sorted(x['gastado'] for x in r)[len(r) // 2]} {arc}")
        print(f"  {sk_n:5s} " + " | ".join(out))
        logros = []
        for d in ORDEN:
            r = [x[d] for x in campañas if d in x]
            mapas = sum(x["mapas"] for x in r) or 1
            logros.append(f"{d} sin daño {sum(x['sin_daño'] for x in r) * 100 // mapas}% "
                          f"matando a todos {sum(x['exterminados'] for x in r) * 100 // mapas}%")
        d_logro = par.logro_dif if par.logro != "completar" else ARCOS[par.arco_logro]["dif"]
        con = sorted(x[d_logro]["logro_en"] for x in campañas if d_logro in x and x[d_logro]["logro_en"])
        nombre = par.arco_logro
        desbloqueo = (f"{nombre} en la partida {con[len(con) // 2]} de {d_logro} ({len(con) * 100 // n}% lo consiguen)"
                      if con else f"{nombre}: nunca en {d_logro}")
        print(f"        mapas superados: " + ", ".join(logros) + f" | {desbloqueo}")

#stats con toda la tienda al máximo (las 9 mejoras: Run Speed y Dodge Speed incluidas)
MAXIMO = dict(dmg=11, rate=2.0, arr=5, hp=60, rng=30, side=250, speed=300)

def fin_de_juego(par, n=200, seed=1):
    """Logros de Hell con la tienda al máximo y cada arco a nivel 5: % de intentos por mapa."""
    random.seed(seed)
    print(f"--- fin de juego: Hell con la tienda al máximo ({n} intentos por mapa)")
    for arco, nivel in [("storm", 5), ("dragon", 1), ("dragon", 3), ("dragon", 5)]:
        for sk_n, sk in SKILLS.items():
            out = []
            for m in (1, 2, 3):
                st = dict(MAXIMO, arco=arco, arco_nivel=nivel)
                c = Counter()
                esc = Counter()
                for _ in range(n):
                    r = jugar_mapa(m, "hell", st, par, sk)
                    esc.update(r["escapados"])
                    if not r["ganado"]:
                        continue
                    c["gana"] += 1
                    rapido = r["tiempo"] < LOGRO_TIEMPO["hell"]
                    c["exterminator"] += r["todos"]
                    c["swift"] += rapido
                    c["perfect"] += r["todos"] and rapido
                    c["sin daño"] += sum(r["causas"].values()) == 0
                out.append(f"mapa {m}: " + " ".join(f"{k} {c[k] * 100 // n}%" for k in
                                                     ["gana", "exterminator", "swift", "perfect", "sin daño"])
                           + " | se escapan por intento: " + ", ".join(f"{k} {v / n:.1f}" for k, v in esc.most_common(3)))
            print(f"  {arco} {nivel} {sk_n}")
            for o in out:
                print("      " + o)

def _valor(texto):
    for tipo in (int, float):
        try:
            return tipo(texto)
        except ValueError:
            pass
    return texto

if __name__ == "__main__":
    ap = argparse.ArgumentParser(description="Simula campañas de Running Archer")
    ap.add_argument("-n", type=int, default=40, help="campañas por jugador (40)")
    ap.add_argument("--seed", type=int, default=1)
    ap.add_argument("--fin", action="store_true", help="logros de Hell con la tienda al máximo (Storm 5 y Dragonbone 1, 3 y 5)")
    ap.add_argument("--set", action="append", default=[], metavar="PARAM=VALOR",
                    help="cambia un parámetro de Parametros (p. ej. g_vida=1.5, estrategia=arco)")
    a = ap.parse_args()
    cambios = {}
    for s in a.set:
        k, v = s.split("=", 1)
        cambios[k] = _valor(v)
    if a.fin:
        fin_de_juego(Parametros(**cambios), max(a.n, 100), a.seed)
    else:
        informe("balance actual" if not cambios else ", ".join(a.set), Parametros(**cambios), a.n, a.seed)
