class_name Progress extends Node

##Señales
signal add_gold(int) #añade oro al hub

var progreso_permanente ={
	"p_speed" : 200,
	"p_side_speed" : 150,
	"p_attack_speed" : 0.5,
	"p_vida" : 10,
	"a_skin" : 1,
	"f_cantidad" : 1,
	"f_velocidad" : 500,
	"f_max_distancia" : 10,
	"f_daño" : 1
}
#Player stats
var p_gold = 0
var current_map = 1
var player
