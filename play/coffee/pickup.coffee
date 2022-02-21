class gg.Pickup extends gg.Sprite
	constructor: (props) ->

		model = gg.weps[ props.states?.model or props.model ]

		props.z = 64
		props.r = 0

		sprite =
			elevation: 2
			path: "nontile/mcitems/#{model.sty}.png"
			# path: "nontile/skeleton.png"
			hasShadow: true
			sprite:
				width: 29
				height: 29

		super props, sprite

		this.model = model

		@type = 'Pickup'

		props.hide = true if not props.net and not gg.ed?

		@build()

		@yaw ?= value: 0, period: 0

		;

	# override
	step: ->
		yaw = @yaw
		
		base = 4

		yaw.period += 0.02 * gg.timestep

		if yaw.period > Math.PI * 2
			yaw.period -= Math.PI * 2

		yaw.value = base * Math.cos yaw.period

		# console.log yaw.value

		@sprite.elevation = base + yaw.value

		@keyframe[2] += 0.016 * 0.5

		super()

		@pose()

		1


class gg.Gun
	constructor: (props, model) -> ;
		#super props, model

class gg.Melee
	constructor: (props, model) -> ;
		# super props, model


gg.trails = []

class gg.Trail
	constructor: (@props) ->
		gg.trails.push this

		@made = Date.now()

		@material = new THREE.LineBasicMaterial color: 0xffffff, transparent: true, opacity: .7
		geometry = new THREE.Geometry
		geometry.vertices.push new THREE.Vector3 @props.x, @props.y, 65
		geometry.vertices.push new THREE.Vector3 @props.to.x, @props.to.y, 65
		@line = new THREE.Line geometry, @material
		gg.scene.add @line

	dtor: ->
		gg.scene.remove @line
		i = gg.trails.indexOf this
		gg.trails.splice i, 1
		true

	step: ->
		@material.opacity -= 0.05

		@dtor() if @made < Date.now()-250

		true



