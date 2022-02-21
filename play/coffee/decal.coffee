class gg.Decal extends gg.Sprite
	constructor: (props) ->

		# props.hide = true

		decal = if props.states then props.states.decal else props.decal
		decal = gg.decals[ decal ] or gg.decals.err

		# props.r = (Math.PI *2) * Math.random()

		decal.scale = 1 if not decal.scale?
		decal.hasShadow = false if not decal.hasShadow?
		decal.normal = false if not decal.normal?

		sprite =
			elevation: .05
			path: decal.sty
			normal: decal.normal
			hasShadow: !! decal.hasShadow
			x: decal.x or 0
			sprite:
				width: decal.sprite.width
				height: decal.sprite.height
			sheet:
				width: decal.sheet.width
				height: decal.sheet.height
			scale: decal.scale

		super props, sprite

		@understeer = false

		@build()

		@type = 'Decal'

		@mesh.ggsolid = this # arb prop

		@frame decal.frame or 0, decal.y

		# @material.polygonOffset = true
		# @material.polygonOffsetFactor = -0.1

		if props.states? and props.states.spin
			@embody()

			@dynamicBody.SetAngularVelocity props.states.spin

		@pose()

	embody: ->
		@bodyDef = new box2d.b2BodyDef()
		@bodyDef.type = box2d.b2BodyType.b2_dynamicBody
		@bodyDef.allowSleep = false

		@circleShape = new box2d.b2CircleShape 1 / gg.scaling

		@fixtureDef = new box2d.b2FixtureDef
		@fixtureDef.shape = @circleShape
		@fixtureDef.density = 1
		@fixtureDef.filter.categoryBits = gg.masks.casings
		@fixtureDef.filter.maskBits = gg.masks.solid | gg.masks.casings

		@bodyDef.position.Set @props.x / gg.scaling, @props.y / gg.scaling
		
		@dynamicBody = gg.world.CreateBody @bodyDef
		@dynamicBody.SetTransform @dynamicBody.GetPosition(), @props.r
		@dynamicBody.CreateFixture @fixtureDef

		@dynamicBody.SetLinearDamping 0.5
		@dynamicBody.SetAngularDamping 2.5

		true


	dtor: ->
		gg.world.DestroyBody @dynamicBody if @dynamicBody?

		@mesh.ggsolid = null
		super()
		true

	step: ->
		# super()

		if @dynamicBody?
			pos = @dynamicBody.GetPosition()

			@props.x = pos.x * gg.scaling
			@props.y = pos.y * gg.scaling
			@props.r = @dynamicBody.GetAngle()

			@pose()
		true

class gg.Tree extends gg.Sprite
	constructor: (props) ->
		props.x = props.actualx if props.actualx?
		props.y = props.actualy if props.actualy?

		sprite =
			elevation: 64
			path: 'nontile/tree.png'
			normal: no
			hasShadow: true
			sprite:
				width: 64
				height: 64
			sheet:
				width: 64
				height: 64
			scale: 1

		super props, sprite
		
		@understeer = false

		gg.tree = this # debug

		# @frame 0, 0

		@type = 'Tree'

		@mesh.ggsolid = this # arb prop

		# trees are ugly, fuck it;
		@pose()

	step: -> no



gg.decals =
	
	err: # PLA CE HOL DER
		sty: 'nontile/casings.png'
		sprite: width: 8, height: 8
		sheet: width: 32, height: 32
		y: .75
		frame: 0
		scale: .37

	# RED BLOODS:
	b0: #
		sty: 'nontile/bloods.png'
		sprite: width: 32, height: 32
		sheet: width: 128, height: 128
		y: .75
		frame: 0
		normal: true

	b1: #
		sty: 'nontile/bloods.png'
		sprite: width: 32, height: 32
		sheet: width: 128, height: 128
		y: .75
		frame: 1
		normal: true

	b2: #
		sty: 'nontile/bloods.png'
		sprite: width: 32, height: 32
		sheet: width: 128, height: 128
		y: .75
		frame: 2
		normal: true

	b3: #
		sty: 'nontile/bloods.png'
		sprite: width: 32, height: 32
		sheet: width: 128, height: 128
		y: .75
		frame: 3
		normal: true

	b4: #
		sty: 'nontile/bloods.png'
		sprite: width: 32, height: 32
		sheet: width: 128, height: 128
		y: .5
		frame: 0
		normal: true

	b5: #
		sty: 'nontile/bloods.png'
		sprite: width: 32, height: 32
		sheet: width: 128, height: 128
		y: .5
		frame: 1
		normal: true

	b6: #
		sty: 'nontile/bloods.png'
		sprite: width: 32, height: 32
		sheet: width: 128, height: 128
		y: .5
		frame: 2
		normal: true

	b7: #
		sty: 'nontile/bloods.png'
		sprite: width: 32, height: 32
		sheet: width: 128, height: 128
		y: .5
		frame: 3
		normal: true

	# GREEN BLOODS
	g0: #
		sty: 'nontile/bloods.png'
		sprite: width: 32, height: 32
		sheet: width: 128, height: 128
		y: .25
		frame: 0
		normal: true

	g1: #
		sty: 'nontile/bloods.png'
		sprite: width: 32, height: 32
		sheet: width: 128, height: 128
		y: .25
		frame: 1
		normal: true

	g2: #
		sty: 'nontile/bloods.png'
		sprite: width: 32, height: 32
		sheet: width: 128, height: 128
		y: .25
		frame: 2
		normal: true

	g3: #
		sty: 'nontile/bloods.png'
		sprite: width: 32, height: 32
		sheet: width: 128, height: 128
		y: .25
		frame: 3
		normal: true

	g4: #
		sty: 'nontile/bloods.png'
		sprite: width: 32, height: 32
		sheet: width: 128, height: 128
		y: 0
		frame: 0
		normal: true

	g5: #
		sty: 'nontile/bloods.png'
		sprite: width: 32, height: 32
		sheet: width: 128, height: 128
		y: 0
		frame: 1
		normal: true

	g6: #
		sty: 'nontile/bloods.png'
		sprite: width: 32, height: 32
		sheet: width: 128, height: 128
		y: 0
		frame: 2
		normal: true

	g7: #
		sty: 'nontile/bloods.png'
		sprite: width: 32, height: 32
		sheet: width: 128, height: 128
		y: 0
		frame: 3
		normal: true
	
	# CASINGS:
	c1: # Shotgun
		sty: 'nontile/casings.png'
		sprite: width: 8, height: 8
		sheet: width: 32, height: 32
		y: .75
		frame: 0
		scale: .37

	c2: # Pistol
		sty: 'nontile/casings.png'
		sprite: width: 8, height: 8
		sheet: width: 32, height: 32
		y: .75
		frame: 1
		scale: .4

	c3: # SMG/Carbine
		sty: 'nontile/casings.png'
		sprite: width: 8, height: 8
		sheet: width: 32, height: 32
		y: .75
		frame: 2
		scale: .4

	c4: # AR
		sty: 'nontile/casings.png'
		sprite: width: 8, height: 8
		sheet: width: 32, height: 32
		y: .75
		frame: 3
		scale: .4

	c5: # DMR/Sniper
		sty: 'nontile/casings.png'
		sprite: width: 8, height: 8
		sheet: width: 32, height: 32
		y: .5
		frame: 0
		scale: .4

	# SCRUBS:
	scrub1:
		sty: 'nontile/scrubs.png'
		sprite: width: 16, height: 16
		sheet: width: 64, height: 64
		y: .75
		frame: 0
		hasShadow: false
		# normal: true
		# scale: 1

	scrub2:
		sty: 'nontile/scrubs.png'
		sprite: width: 32, height: 32
		sheet: width: 64, height: 64
		x: 16
		y: .5
		frame: 0
		hasShadow: false
		# normal: true
		# scale: 1