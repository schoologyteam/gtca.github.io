
# look below for cars

class gg.Car extends gg.Sprite
	constructor: (props) ->

		unless model = gg.Cars.TYPES[ props.states.m ]
			console.error "bad car model `#{props.states.m}`"

		color = props.states.c or no

		_color = if color then "_#{color}" else ''
		path = "nontile/cars/#{model.props.sty}#{_color}.png"
		gg.loadSty "#{path.split('.png')[0]}_deltas.png"


		sprite =
			elevation: 2
			path: path
			normalPath: "nontile/cars/#{model.props.sty}normal.png"
			normal: true
			hasShadow: true
			sprite:
				width: model.props.width
				height: model.props.height

		super props, sprite

		this.path = path
		
		@deltas = {} # assoc

		@phys = 
			push: .1
			spring: .0
			slip: .0
			slipness: 0
			stiff: 0
			lastr: props.r

		@engineon = false
		@readytime = 0
		@lastSound = null
		@lastb = false

		this.color = color
		this.driver = false
		this.model = model

		@__car =
			headlights: false
			taillights: false

		@build()

		@type = 'Car'

		@tune = null

		@carengine = null

		@embody()

		gg.clonecarmaterial this

		# @to = new THREE.AxisHelper
		# @from = new THREE.AxisHelper

		# gg.scene.add @to
		# gg.scene.add @from

	# override
	dtor: ->
		gg.scene.remove @headlights if gg.settings.fancyHeadlights

		@deltas[_DELTAS.tail_light_left.nr]?.dtor()
		@deltas[_DELTAS.tail_light_right.nr]?.dtor()

		@deltas[_DELTAS.head_light_left.nr]?.dtor()
		@deltas[_DELTAS.head_light_right.nr]?.dtor()

		gg.world.DestroyBody @dynamicBody if @dynamicBody?

		super()

		1

	embody: ->
		gg.world.DestroyBody @dynamicBody if @dynamicBody?

		@bodyDef = new box2d.b2BodyDef()

		if @driver
			@bodyDef.type = box2d.b2BodyType.b2_dynamicBody
		else
			@bodyDef.type = box2d.b2BodyType.b2_staticBody

		@bodyDef.allowSleep = false
		
		@polygonShape = new box2d.b2PolygonShape
		@polygonShape.SetAsBox (@model.props.sizew / 2) / gg.scaling, (@model.props.sizeh / 2) / gg.scaling

		@fixtureDef = new box2d.b2FixtureDef
		@fixtureDef.shape = @polygonShape
		@fixtureDef.density = 1
		#@fixtureDef.filter.categoryBits = gta.masks.solid
		#@fixtureDef.filter.maskBits = -1

		@bodyDef.position.Set @props.x / gg.scaling, @props.y / gg.scaling
		@dynamicBody = gg.world.CreateBody @bodyDef
		@dynamicBody.CreateFixture @fixtureDef
		@dynamicBody.SetTransform @dynamicBody.GetPosition(), @props.r

		@dynamicBody.SetLinearDamping 6
		@dynamicBody.SetAngularDamping 5
		true

	# override
	patch: (o) ->
		super o

		@state o

		1

	# override
	pose: ->
		super()

		v.pose() for k, v of @deltas
		
		1

	state: (o, first) ->

		return unless o.states?

		STATE = o.states
		
		if STATE.h?
			gg.play gg.sounds.impacts[ STATE.h ], this, 70

		if STATE.l?

			console.log "headlights is #{STATE.l}"
			
			if 0 is STATE.l and true is @__car.headlights

				console.log 'rmdelta lights'

				@rmdelta _DELTAS.head_light_left
				@rmdelta _DELTAS.head_light_right

				@__car.headlights = false

			else if 1 is STATE.l and false is @__car.headlights

				console.log 'making lights'

				# a = @delta _DELTAS.Dent_behind_right
				l = @delta _DELTAS.head_light_left, 'Pale Nimbus'
				r = @delta _DELTAS.head_light_right, 'Pale Nimbus'

				gg.flipplane l.geometry, 0, true

				l.material.emissive = r.material.emissive = new THREE.Color 0x333333

				@__car.headlights = true

		if STATE.b?

			console.log "taillights is #{STATE.b}"

			if 0 is STATE.b and true is @__car.taillights

				@rmdelta _DELTAS.tail_light_left
				@rmdelta _DELTAS.tail_light_right

				@__car.taillights = false

			else if 1 is STATE.b and false is @__car.taillights

				l = @delta _DELTAS.tail_light_left, 'Radish'
				r = @delta _DELTAS.tail_light_right, 'Radish'

				gg.flipplane l.geometry, 0, true

				l.material.emissive = r.material.emissive = new THREE.Color 0x220000

				@__car.taillights = true

		true

	rmdelta: (delta) ->

		console.log 'rmdelta ' + delta

		@deltas[ delta.nr ]?.dtor()

		delete @deltas[ delta.nr ]

		# @deltas[delta.nr] = null

		0

	delta: (delta, salt) ->

		i = delta.nr

		sprite =
			elevation: 2
			path: "#{@path.split('.png')[0]}_deltas.png"
			salt: salt
			hasShadow: no
			sprite:
				width: @model.props.width
				height: @model.props.height

		d = @model.deltas[i]

		# todo use the lighter spriteclone ?

		v = @deltas["#{i}"] ?= new gg.Sprite @props, sprite
		gg.posplane v.geometry, 0, d.x, d.y, d.w, d.h

		v.build true

		v

	dooring: (i, f) ->
		door = @model.props.doors[i]
		flip = 'right' is door.side

		if not flip
			if i < 2
				switch f
					when 0
						@rmdelta _DELTAS.driver_door_open
					when 1
						@rmdelta _DELTAS.driver_door_almost_open
						@delta _DELTAS.driver_door_open
					when 2
						@rmdelta _DELTAS.driver_door_open
						@rmdelta _DELTAS.driver_door_slightly_open
						@delta _DELTAS.driver_door_almost_open
					when 3
						@rmdelta _DELTAS.driver_door_almost_open
						@rmdelta _DELTAS.driver_door_almost_closed
						@delta _DELTAS.driver_door_slightly_open
					when 4
						@rmdelta _DELTAS.driver_door_slightly_open
						@delta _DELTAS.driver_door_almost_closed
					when 5
						@rmdelta _DELTAS.driver_door_almost_closed
			else
				switch f
					when 0
						@rmdelta _DELTAS.rear_door_left_open
					when 1
						@rmdelta _DELTAS.rear_door_left_almost_open
						@delta _DELTAS.rear_door_left_open
					when 2
						@rmdelta _DELTAS.rear_door_left_open
						@rmdelta _DELTAS.rear_door_left_slightly_open
						@delta _DELTAS.rear_door_left_almost_open
					when 3
						@rmdelta _DELTAS.rear_door_left_almost_open
						@rmdelta _DELTAS.rear_door_left_almost_closed
						@delta _DELTAS.rear_door_left_slightly_open
					when 4
						@rmdelta _DELTAS.rear_door_left_slightly_open
						@delta _DELTAS.rear_door_left_almost_closed
					when 5
						@rmdelta _DELTAS.rear_door_left_almost_closed
		else
			d = null
			if i < 2
				switch f
					when 0
						@rmdelta _DELTAS.passenger_door_open
					when 1
						@rmdelta _DELTAS.passenger_door_almost_open
						d = @delta _DELTAS.passenger_door_open
					when 2
						@rmdelta _DELTAS.passenger_door_open
						@rmdelta _DELTAS.passenger_door_slightly_open
						d = @delta _DELTAS.passenger_door_almost_open
					when 3
						@rmdelta _DELTAS.passenger_door_almost_open
						@rmdelta _DELTAS.passenger_door_almost_closed
						d = @delta _DELTAS.passenger_door_slightly_open
					when 4
						@rmdelta _DELTAS.passenger_door_slightly_open
						d = @delta _DELTAS.passenger_door_almost_closed
					when 5
						@rmdelta _DELTAS.passenger_door_almost_closed
			else
				switch f
					when 0
						@rmdelta _DELTAS.rear_door_right_open
					when 1
						@rmdelta _DELTAS.rear_door_right_almost_open
						d = @delta _DELTAS.rear_door_right_open
					when 2
						@rmdelta _DELTAS.rear_door_right_open
						@rmdelta _DELTAS.rear_door_right_slightly_open
						d = @delta _DELTAS.rear_door_right_almost_open
					when 3
						@rmdelta _DELTAS.rear_door_right_almost_open
						@rmdelta _DELTAS.rear_door_right_almost_closed
						d = @delta _DELTAS.rear_door_right_slightly_open
					when 4
						@rmdelta _DELTAS.rear_door_right_slightly_open
						d = @delta _DELTAS.rear_door_right_almost_closed
					when 5
						@rmdelta _DELTAS.rear_door_right_almost_closed

			gg.flipplane d.geometry, 0, true if d?

		@pose()
		0

	lights: ->
		return unless @engineon and gg.settings.fancyHeadlights
		@headlights = new THREE.SpotLight 0xffffff
		@headlights.intensity = 1
		@headlights.angle /= 2.5
		@headlights.penumbra = .25
		@headlights.decay = 1.5
		@headlights.distance = 64*5
		
		gg.scene.add @headlights
		gg.scene.add @headlights.target
		1

	# override
	step: ->

		if (@driver or @passenger) and gg.keys[69] is 1 # e
			@exit()
			return

		else if @driver

			pos = @dynamicBody.GetPosition()
			@props.x = pos.x * gg.scaling
			@props.y = pos.y * gg.scaling
			@props.r = @dynamicBody.GetAngle()

			@pose()
			
			if not @engineon
				if @readytime <= Date.now()
					@engineon = true
					gg.zoom = gg.C.ZOOM.CAR

					@lights()

				else return

			###if @engineon
				you.props.x = @props.x
				you.props.y = @props.y
				you.props.z = @props.z
				you.props.r = @props.r###

		else
			super()
			
			@dynamicBody.SetPosition new box2d.b2Vec2 @props.x / gg.scaling, @props.y / gg.scaling
			@dynamicBody.SetTransform @dynamicBody.GetPosition(), @props.r
			@dynamicBody.SetAngularVelocity 0
			@dynamicBody.SetLinearVelocity new box2d.b2Vec2 0, 0

			@pose()

			if @passenger

				gg.zoom = gg.C.ZOOM.CAR
				
				###you.props.x = @props.x
				you.props.y = @props.y
				you.props.z = @props.z
				you.props.r = @props.r###

			return

		if gg.settings.fancyHeadlights
			a = gg.pivot @props.x, @props.y-@model.props.height/2+32, @props.r, @props.x, @props.y
			@headlights.position.set a.x, a.y, @props.z+36
			# @from.position.set a.x, a.y, @props.z+36

			a = gg.pivot @props.x, @props.y-@model.props.height/2, @props.r, @props.x, @props.y
			@headlights.target.position.set a.x, a.y, @props.z+16
			# @to.position.set a.x, a.y, @props.z+16

		@gas = !! gg.keys[87] and not gg.keys[83]
		@brake = !! gg.keys[83] and not gg.keys[87]
		@left = !! gg.keys[65] and not gg.keys[68]
		@props.right = !! gg.keys[68] and not gg.keys[65]

		@springing()

		# gg.net.out.d = @gas
		b = not @gas and not @reversing

		gg.net.out.b = b if @lastb isnt b

		@lastb = b
		
		@reversing = @gas

		###to =
			x: @props.x + @box.velocity.x
			y: @props.y + @box.velocity.y

		delta =
			x: @props.x - to.x
			y: @props.y - to.y

		float = normalize @box.angle
		float /= Math.PI*2
		float += 1 if float < 0

		theta = Math.atan2 delta.y, delta.x

		go = ( theta / (Math.PI*2) ) + .5
		go -= .25
		go += 1 if go < 0

		dif = Math.abs float-go

		reversing = dif < 0.1 or dif > 0.9###

		reversing = false

		# turn
		if @phys.spring
			spring = @phys.spring

			if reversing
				spring = -@phys.spring

			# @phys.stiff = Math.abs( ( (@phys.push/@model.phys.max) *0.4 ) - 1)

			r = @model.phys.drotate * spring # * @phys.stiff
			motion = @dynamicBody.GetLinearVelocity().Length()
			r *= (motion / 10) / @model.wheelbase

			@dynamicBody.ApplyTorque r * 100000
			# @dynamicBody.ApplyAngularImpulse r * 10000

			# @dynamicBody.SetTransform @dynamicBody.GetPosition(), @props.r + r
			#Matter.Body.rotate @box, r

		# slippery tarmac
		@phys.slipness -= 0.05 if @phys.slipness > 0

		@phys.slip = Math.abs(@phys.lastr-@props.r)*(@phys.push/@model.phys.max)*10
		if @phys.slip >= .5
			@phys.push -= @model.phys.dslip * .01666
			@phys.slipness += 0.2 if @phys.slipness < 1

		# @box.frictionAir = @model.phys.airFriction - (@phys.slipness * 0.02 )

		# push pull
		if @gas and @phys.push < @model.phys.max
			@phys.push += @model.phys.daccelerate * .01666
			@phys.push += @model.phys.dbrake * .01666 if @phys.push < 0

		else if @brake
			@dobrake()

		@propel()

		rate = @phys.push / 10

		#@carengine._rate = rate

		@phys.lastr = @props.r

		super()

		true

	springing: ->
		damp = 0.1
		if @left
			@phys.spring = if @phys.spring < 1 then @phys.spring+damp else 1
		else if @props.right
			@phys.spring =  if @phys.spring > -1 then @phys.spring-damp else -1
		else if @phys.spring
			if @phys.spring > 0
				@phys.spring = if @phys.spring-damp < 0 then 0 else @phys.spring - damp
			else if @phys.spring < 0
				@phys.spring = if @phys.spring + damp > 0 then 0 else @phys.spring + damp

		true

	dobrake: ->
		if @phys.push > 0 # brake
			@reversing = false

			if @phys.push - (@model.phys.dbrake * .01666) > 0
				@phys.push -= @model.phys.dbrake * .01666
			else
				@phys.push = 0
		else # reverse
			@reversing = true
			if @phys.push > -@model.phys.bmax and @phys.push - (@model.phys.dreverse * .01666) > -@model.phys.bmax
				@phys.push -= @model.phys.dreverse * .01666
			else
				@phys.push = -@model.phys.bmax

		true

	propel: ->
		if not @gas and not @brake

			droll = @model.phys.droll * .01666

			if @phys.push - droll > 0
				@phys.push -= droll
			else if @phys.push + droll < 0
				@phys.push += droll
			else
				@phys.push = 0
				#@stopengine()
		
		angle = @props.r - (Math.PI/2)
		m = 150
		x = (@phys.push*m) * Math.cos angle
		y = (@phys.push*m) * Math.sin angle

		to = new box2d.b2Vec2 x, y

		# @dynamicBody.ApplyLinearImpulse to, @dynamicBody.GetWorldCenter()
		@dynamicBody.ApplyForce to, @dynamicBody.GetWorldCenter()
		#Matter.Body.applyForce @box, {x:x,y:y}, {x:x,y:y}

		true

	reset: ->
		@phys.push = 0
		@phys.spring = 0
		@phys.slip = 0
		@phys.stiff = 0

		1

	enter: (man) ->

		return unless man is gg.ply

		@reset()

		@passenger = 0 isnt man._MAN._cd.i
		@driver = ! @passenger
		
		if not @passenger
			gg.bubble 'You\'re driving.'
			@props.net = false

		else
			gg.bubble 'This is a passenger seat.'
			@props.net = true

		@embody()

		man.car = this

		###man.props.x = @props.x
		man.props.y = @props.y
		man.props.z = @props.z
		man.props.r = @props.r###

		gg.ply = this

		# gg.net.out.CAR = [@props.x, @props.y, @props.r, @props.z] # this wasnt that useful / implied

		@readytime = Date.now()+750 # time before you can use the vehicle

		true

	exit: () ->

		# return unless man is gg.ply

		@props.net = true

		gg.net.out.EXITCAR = true

		@passenger = false

		@driver = false

		if gg.settings.fancyHeadlights
			gg.scene.remove @headlights
			gg.scene.remove @headlights.target

		gg.play gg.sounds.cardoor[0], this

		cb = => gg.play gg.sounds.cardoor[1], this

		setTimeout cb, 600

		gg.zoom = gg.C.ZOOM.PED

		@readytime = 0
		@engineon = false

		gg.net.out.CAR = [ @props.x, @props.y, @props.r, @props.z ] # last car coords before on foot

		1

	###raise: ->
		gg.Sprite::raycaster.ray.origin.copy new THREE.Vector3 @props.x, @props.y, @props.z+1
		hit = gg.Sprite::raycaster.intersectObject @on.mesh

		@props.z = hit[0]?.point?.z+1 or @on.raise.mean

		0###

class gg.Cars
	constructor: (@props) ->

		@props.colors = [] if not @props.colors?

		@speed = @props.speed or .5
		@wheelbase = @props.wheelbase or 2
		@handling = @props.handling or .5
		@weight = @props.weight or 0.001 * 15
		@grip = @props.grip or .5
		
		max = @speed * 10 # catalysts for physic vars psychic

		@phys =
			max: max
			bmax: max / 2.5
			drotate: @props.handling / 100
			daccelerate: max / 2.5
			dbrake: max * 2
			dreverse: max / 4
			droll: max / 3 # how much a car rolls out
			dslip: max * 2.5
			airFriction: ( @grip * .02 ) + 0.04

		@deltas = {} # assoc

		for k, v of _DELTAS

			Y = if v.y is 1 then 0 else 1

			W = @props.width * 10 + 9*4
			H = @props.height * 2 + 4

			x = v.x * @props.width + v.x*4
			y = Y * @props.height + Y*4

			w = @props.width
			h = @props.height

			@deltas["#{v.nr}"] = x: x/W, y: y/H, w: w/W, h: h/H

		

gg.Cars.TYPES = {}

###_DELTAS =
	DentBehindLeft
	DentBehindRight
	DentFrontRight
	DentFrontLeft
	UnusedOriginalVehiclesHaveADentInTheRoofHere
	TailLightRight
	TailLightLeft
	HeadLightRight
	HeadLightLeft
	DriverDoorAlmostClosed
	DriverDoorSlightlyOpen
	DriverDoorAlmostOpen
	DriverDoorOpen
	PassengerDoorAlmostClosed
	PassengerDoorSlightlyOpen
	PassengerDoorAlmostOpen
	PassengerDoorOpen
	RearDoorLeftAlmostClosed
	RearDoorLeftSlightlyOpen
	RearDoorLeftAlmostOpen
	RearDoorLeftOpen
	RearDoorRightAlmostClosed
	RearDoorRightSlightlyOpen
	RearDoorRightAlmostOpen
	RearDoorRightOpen###

_DELTAS = 
	dent_behind_left:
		nr: '1'
		x: 0
		y: 0

	dent_behind_right:
		nr: '2'
		x: 1
		y: 0

	dent_front_right:
		nr: '3'
		x: 2
		y: 0

	dent_front_left:
		nr: '4'
		x: 3
		y: 0

	unused_original_vehicles_have_a_dent_in_the_roof_here:
		nr: '5'
		x: 4
		y: 0

	tail_light_right:
		nr: '6'
		x: 5
		y: 0

	tail_light_left:
		nr: '6.5'
		x: 5
		y: 0

	head_light_right:
		nr: '7'
		x: 6
		y: 0

	head_light_left:
		nr: '7.5'
		x: 6
		y: 0

	driver_door_almost_closed:
		nr: '8'
		x: 7
		y: 0

	driver_door_slightly_open:
		nr: '9'
		x: 8
		y: 0

	driver_door_almost_open:
		nr: '10'
		x: 9
		y: 0

	driver_door_open:
		nr: '11'
		x: 0
		y: 1

	passenger_door_almost_closed:
		nr: '8.5'
		x: 7
		y: 0

	passenger_door_slightly_open:
		nr: '9.5'
		x: 8
		y: 0

	passenger_door_almost_open:
		nr: '10.5'
		x: 9
		y: 0

	passenger_door_open:
		nr: '11.5'
		x: 0
		y: 1

	rear_door_left_almost_closed:
		nr: '12'
		x: 1
		y: 1

	rear_door_left_slightly_open:
		nr: '13'
		x: 2
		y: 1

	rear_door_left_almost_open:
		nr: '14'
		x: 3
		y: 1

	rear_door_left_open:
		nr: '15'
		x: 4
		y: 1

	rear_door_right_almost_closed:
		nr: '12.5'
		x: 1
		y: 1

	rear_door_right_slightly_open:
		nr: '13.5'
		x: 2
		y: 1

	rear_door_right_almost_open:
		nr: '14.5'
		x: 3
		y: 1

	rear_door_right_open:
		nr: '15.5'
		x: 4
		y: 1