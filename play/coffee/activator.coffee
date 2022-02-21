class gg.Activator extends gg.Sprite
	idpool: 0

	constructor: (props) ->

		# console.log "new activator at #{props.x} #{props.y} #{props.z}"

		props.id = --Activator::idpool if not props.id?

		model = gg.activators[ props.type ] or gg.activators.err

		if model.anim?
			anim = JSON.parse JSON.stringify model.anim


		sprite =
			elevation: model.elevation
			path: model.texture
			hasShadow: model.hasShadow
			x: model.x or 0
			sprite:
				width: model.sprite.width
				height: model.sprite.height
			sheet:
				width: model.sheet.width
				height: model.sheet.height

		super props, sprite

		@understeer = false

		@anim = anim
		@model = model

		@build()

		@type = 'Activator'

		@frame model.frame or 0, model.y

		@embody() if model.solid

		@state props, true
		
		@pose()

		;

	# override
	patch: (o) ->
		super o

		@state o
		
		true

	embody: ->
		@bodyDef = new box2d.b2BodyDef()
		@bodyDef.type = box2d.b2BodyType.b2_staticBody

		x = @props.x / gg.scaling
		y = @props.y / gg.scaling

		@bodyDef.position.Set x, y

		@polygonShape = new box2d.b2PolygonShape
		@polygonShape.SetAsBox (@model.sprite.width / 2) / gg.scaling, (@model.sprite.height / 2) / gg.scaling

		@fixtureDef = new box2d.b2FixtureDef
		@fixtureDef.shape = @polygonShape

		@fixtureDef.filter.categoryBits = gg.masks.solid
		@fixtureDef.filter.maskBits = -1

		@body = gg.world.CreateBody @bodyDef
		@body.SetTransform @body.GetPosition(), @props.r
		@body.CreateFixture @fixtureDef
		true

	dtor: ->
		@mesh.ggsolid = null
		super 1
		true

	state: -> 0

	step: ->
		super()

		if @anim?
			gg.anim.call @anim
			frame = @anim.i

			@frame frame, @model.y

		@pose()

		true

class gg.Furniture extends gg.Activator
	constructor: (props) ->
		super props


class gg.ATM extends gg.Activator
	constructor: (props) ->
		super props


	state: (o) ->
		#true

	gui: ->
		0

	# override
	dtor: ->
		super()

class gg.VendingMachine extends gg.Activator
	constructor: (props) ->
		super props


	state: (o) ->
		#true

	gui: ->
		0

	# override
	dtor: ->
		super()

class gg.LabFreezer extends gg.Activator
	constructor: (props) ->
		super props

		x = props.x + 5 * Math.cos props.r - (Math.PI/2)
		y = props.y + 5 * Math.sin props.r - (Math.PI/2)

		###@light = new THREE.PointLight 0xa7bcff, .6, 64
		@light.position.set x, y, @props.z + 8
		gg.scene.add @light

		gg.map.build = true###

	#state: (o) ->
		#if o.states.u?

			#true

		#true

	gui: ->
		0

	# override
	dtor: ->
		gg.scene.remove @light
		super()

class gg.VacuumOven extends gg.Activator
	constructor: (props) ->
		super props

		x = props.x + 5 * Math.cos props.r - (Math.PI/2)
		y = props.y + 5 * Math.sin props.r - (Math.PI/2)

		###@light = new THREE.PointLight 0xa7bcff, .6, 64
		@light.position.set x, y, @props.z + 8
		gg.scene.add @light

		gg.map.build = true###

	gui: ->
		0

	# override
	dtor: ->
		gg.scene.remove @light
		super()

class gg.Incubator extends gg.Activator
	constructor: (props) ->
		super props

		x = props.x + 8 * Math.cos props.r - (Math.PI/2)
		y = props.y + 8 * Math.sin props.r - (Math.PI/2)

		###@light = new THREE.PointLight 0xa7bcff, .6, 64
		@light.position.set x, y, @props.z + 8
		gg.scene.add @light

		gg.map.build = true###

	#state: (o) ->
		#if o.states.u?

			#true

		#true

	gui: ->
		0

	# override
	dtor: ->
		gg.scene.remove @light
		super()

class gg.Generator extends gg.Activator
	constructor: (props) ->
		super props

		#@light = new THREE.PointLight 0xff8f8f, .6, 32
		#@light.position.set @props.x, @props.y, @props.z + 8
		#gg.scene.add @light

		gg.map.build = true

	# override
	dtor: ->
		#gg.scene.remove @light
		super()

class gg.Worklight extends gg.Activator
	constructor: (props) ->
		super props

		@light = null
		;

	# override
	state: (o) ->
		return unless o.states?

		if o.states.o?

			if o.states.o and (gg.interior? and o.states.intr? or not gg.interior?)
				if not @light?
					@light = new THREE.PointLight 0xffffff, 2, 64*5
					@light.position.set @props.x, @props.y, @props.z + 24
					gg.scene.add @light
					gg.map.build = true
			else if @light?
				gg.scene.remove @light
				@light = null
				gg.map.build = true

		true

	# override
	dtor: ->
		gg.scene.remove @light if @light?
		super()

class gg.Terminal extends gg.Activator
	constructor: (props) ->
		super props

		x = props.x + 5 * Math.cos props.r - (Math.PI/2)
		y = props.y + 5 * Math.sin props.r - (Math.PI/2)

		###@light = new THREE.PointLight 0xa7bcff, .6, 64
		@light.position.set x, y, @props.z + 8
		gg.scene.add @light

		gg.map.build = true###

		@thing =
		'<om:terminal>
			<om:screen>
				Terminal...
			</om:screen>

			<om:deck>
				<!-- <om:vent></om:vent>
				<om:vent></om:vent>
				<om:vent></om:vent>
				<om:vent></om:vent>
				<om:vent></om:vent> -->

				<om:power>onn</om:power>
				<!-- <om:knob></om:knob> -->
			</om:deck>
		</om:terminal>'

		# $('#overlay').append @thing

	# override
	state: (o) ->
		return unless o.states?

		# if o.states.use?


		true

	# override
	dtor: ->
		gg.scene.remove @light if @light?
		super()

class gg.Teleporter extends gg.Activator
	constructor: (props) ->

		super props
		
		@light = null

		@topmaterial = new THREE.MeshLambertMaterial
				color: if not @props.interior then gg.ambient else gg.intrcolor
				map: @sty
				transparent: true
				side: THREE.FrontSide

		@topgeometry = new THREE.PlaneBufferGeometry @sprite.sprite.width * @sprite.scale, @sprite.sprite.height * @sprite.scale, 1

		@topmesh = new THREE.Mesh @topgeometry, @topmaterial

		@topmesh.position.set @props.x, @props.y, @props.z + 12
		@topmesh.rotation.z = @props.r

		gg.scene.add @topmesh

		@frame 1, @model.y, @topgeometry

		;

	# override
	state: (o) ->
		return unless o.states?

		if o.states.o?

			if o.states.o and (gg.interior? and o.states.intr? or not gg.interior?)
				if not @light?
					@light = new THREE.PointLight 0xc3d1ff, 2, 256
					@light.position.set @props.x, @props.y, @props.z + 32
					gg.scene.add @light
					gg.map.build = true
			else if @light?
				gg.scene.remove @light
				@light = null
				gg.map.build = true

		true

	# override
	dtor: ->
		gg.scene.remove @topmesh
		gg.scene.remove @light if @light?
		super()

class gg.Cable
	@power =
		sprite: width: 8, height: 31
		sheet: width: 128, height: 128
		x: 120
		y: 1 - ((1/128)*13)
		frame: 0

	constructor: (props) ->

		console.log "new cable "

		cable = @power

	dtor: -> ;

class gg.Dumpster extends gg.Activator
	constructor: (props) ->
		super props