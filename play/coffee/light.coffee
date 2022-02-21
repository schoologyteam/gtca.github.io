
# yellow			0xdbcb8a
# warm				0xcfc392
# snot 				0xc8d2a1
# hallowed blue 	0xa1c2d2
# graveyard purple  0x92a2cf

gg._lights = 0

class gg.Light extends gg.Entity
	@color: 0xfdff6c
	
	constructor: (props) ->
		super props

		@type = 'Light'

		@light = null

		@grid = yes
		@color = 0xffffff

		# isinterior = gg.interior? and gg.interior.name isnt @props.interior

		# notinterior = r.interior and (not gg.interior? or r.interior isnt gg.interior.name)

		# if isinterior or notinterior
			# console.warn 'this light isnt interior'
			# @valid = false
			# return

		@shape()
		
		@pose()

		gg.map.build = true
		;

	pose: ->
		@light?.position.set (@props.x*64)+32, (@props.y*64)+32, (@props.z*64) + 32
		1

	shape: ->
		intensity = if @props.interior then 0.65 else 1.25
		radius = if @props.interior then 64*4 else 64*4

		intensity = @vjson.intensity if @vjson.intensity
		radius = @vjson.radius*64 if @vjson.radius

		color = 0xdbcb8a

		@light = new THREE.PointLight color, intensity, radius
		@light.castShadow = false
		@light.color.setHex @vjson.color if @vjson.color?

		@light._visual = this

		# @light = null

		1

	reload: ->
		@light.color.setHex @vjson.color or 0xffffff
		@light.intensity = @vjson.intensity if @vjson.intensity?
		@light.distance = @vjson.radius*64 if @vjson.radius?

		1
		
	build: (solo = false) ->

		0

	dtor: ->

		@light?._visual = null

		# super()

		1
