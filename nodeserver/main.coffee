fs = require('fs')
colors = require('colors')
box2d = require('box2dweb')
WebSocketServer = require('ws').Server

Math.hypot = Math.hypot || () ->
	y = 0
	length = arguments.length

	for i in [0..length-1]
		if arguments[i] is Infinity || arguments[i] is -Infinity
			return Infinity
		y += arguments[i] * arguments[i]

	return Math.sqrt(y)

random = (a) -> a[ Math.floor Math.random() * a.length ]

gta = global.gta =
	id: 1
	sessions: []
	chunks: {} # assoc
	hashes: []
	raws: {}
	frame: 0 # -9007199254740992
	ping: 100
	reduce: 2
	chunksize: 5
	scaling: 14

	stats:
		bytesin: 0
		bytesout: 0
		
	nosj: JSON.parse fs.readFileSync '../sons/nosj.json', 'utf8'
	cars: JSON.parse fs.readFileSync '../sons/cars.json', 'utf8'
	weps: JSON.parse fs.readFileSync '../sons/weps.json', 'utf8'
	items: JSON.parse fs.readFileSync '../sons/items.json', 'utf8'
	activators: JSON.parse fs.readFileSync '../sons/activators.json', 'utf8'

	surround: [
		[[-2, 2], [-1, 2], [0, 2], [1, 2], [2, 2]],
		[[-2, 1], [-1, 1], [0, 1], [1, 1], [2, 1]],
		[[-2, 0], [-1, 0], [0, 0], [1, 0], [2, 0]],
		[[-2,-1], [-1,-1], [0,-1], [1,-1], [2,-1]],
		[[-2,-2], [-1,-2], [0,-2], [1,-2], [2,-2]]]

	timestep: 1.0 / 60.0
	world: null
	intrs: []

	walks: []
	walksbych: {}

	drives: []
	
	entities: []	
	entitiesbych: {}

	parkingspaces: []
	parkingspacesbych: {}
	nearestparkingspacesbych: []

	pickuppool: -1
	decalpool: 0
	activatorpool: 0

	globalbubbles: []

	masks:
		none: 0x0000

		solid: 0x0001
		organic: 0x0002
		items: 0x0004

		introrganic: 0x0008
		intrsolid: 0x00016
		intritems: 0x00032

	DEGTORAD: 0.0174532925199432957
	RADTODEG: 57.295779513082320876

	drops:
		Makeshift: [ 'Shank', 'Kitchen Knife']
		Common: [ 'Combat Knife', 'M9', 'FN 57', 'Compact 45', 'M1911', 'MP412 REX', 'UMP', 'AK-12', 'Mare\'s Leg' ]
		Uncommon: [ 'Machete', 'SPAS-12', 'G36C', 'M4A1', 'AN-94', '.44 Magnum', 'SKS', 'Scout Elite' ]
		Mediumrare: [ 'Carbon Knife', 'Desert Eagle', 'HK416', 'M16A4', 'AEK-971', 'SCAR-H', 'SVD-12', 'Mk 11', 'M40A5' ]
		Rare: [ 'Dragon Knife', 'AS Val', 'RPG', 'Intervention' ]

	chances: [24, 36, 20, 14, 6] # adds up to 100

	colors:
		Makeshift: 	'smokewhite'
		Common: 	'smokewhite' # '#8897FF' # blue
		Uncommon: 	'#D8D795' # yellowish
		Mediumrare: '#8897FF' # blue #BD64E2' # pink
		Rare: 		'#B25EFF' # purple

	foods: [
		'Water bottle'
		'Canned beans'
		'Cabbage'
		'Soda'
	]

gta.hz = 1000 / gta.ping

gta.chunklife = 60000 / gta.ping / 4
gta.chunkunits = gta.chunksize * 64


console.log ''
console.log "     -~=. GTA2.0 Node.js server .=~-".green
console.log "       server runs at #{gta.hz} Hz / #{gta.ping} ms".cyan
console.log ''


IRCNAME = Math.random().toString(36).substring(7) # .replace '.', ''


gta.start = ->
	gta.timer()

	gta.weighted = gta.weigh gta.chances, Object.keys gta.drops


	gta.chunkify()

	console.log 'making server'
	wss = new WebSocketServer port: 8887

	gravity = new box2d.Common.Math.b2Vec2 0, 0
	gta.world = new box2d.Dynamics.b2World gravity, false

	listener = new box2d.Dynamics.b2ContactListener

	listener.BeginContact = (contact) ->
		a = contact.GetFixtureA().GetBody().GetUserData()
		b = contact.GetFixtureB().GetBody().GetUserData()

		return unless a? and b?

		a.beginContact b

		return

	listener.PostSolve = (contact, impulse) ->
		a = contact.GetFixtureA().GetBody().GetUserData()
		b = contact.GetFixtureB().GetBody().GetUserData()
		n = impulse.normalImpulses[0]

		a.postSolve b, n

		return

	gta.world.SetContactListener listener

	true

	wss.on 'connection', (ws) ->
		id = gta.id++

		ses = new Session id, ws
		gta.sessions.push ses

		ws.on 'message', (message) ->
			ses.read message

		ws.on 'close', ->
			ses.close()
			i = gta.sessions.indexOf ses
			gta.sessions.splice i, 1

		ws.send JSON.stringify [{YOURE: id}]

		true

	setInterval gta.loop, gta.ping
	setInterval gta.worldstep, gta.timestep * 1000
	setInterval gta.timer, 1000

	true

pad = (v, w) ->
	v = "0#{v}" while v.length < w
	v

zeroorone = (bool) -> if bool then 1 else 0

gta.timer = ->

	size = gta.sessions.filter( (v) -> return v != undefined).length # fancy array length ?
	
	players = pad "#{size}", 2
	io = pad "#{gta.stats.bytesin/1000}", 3
	oi = pad "#{gta.stats.bytesout/1000}", 3
	frame = pad "#{gta.frame}", 5 # 16

	chunks = Object.keys(gta.chunks).length

	visuals = 0
	visuals += c.visuals.length for i, c of gta.chunks

	sleeping = 0
	for i, c of gta.chunks
		sleeping += 1 if c.sleeping

	process.title = "players: #{players}, in: #{io} KB/sec, out: #{oi} KB/sec"
	process.title += " frame: #{frame}, chunks: #{chunks}(#{sleeping})"
	process.title += ", visuals: #{visuals}"

	gta.stats.bytesin = 0.0
	gta.stats.bytesout = 0.0

	###for ses in gta.sessions
		kb = ses.outed / 1000
		if not ses.megabyte and kb > 500
			ses.megabyte = true###
	true

gta.worldstep = ->
	gta.world.Step 1/60, 3, 2
	# gta.world.ClearForces()
	true

gta.loop = ->

	for i, c of gta.chunks
		delete gta.chunks[i] if not c.step()

	for i, c of gta.chunks
		c.observed = false
		c.firststep = false

	for i, o of gta.intrs
		delete gta.intrs[i] if not o.step()

	c.compile() for i, c of gta.chunks

	for ses, i in gta.sessions
		ses.step()

		a = ses.pack()

		continue unless a.length

		json = JSON.stringify a

		ses.send json

	c.after() for i, c of gta.chunks

	gta.globalbubbles = []

	gta.frame = if gta.frame+1 is 9007199254740992 then 0 else gta.frame+1

	true


gta.chunkify = ->
	for r in @nosj.visuals
		switch r.type
			when 'Entity', 'Walk', 'Drive', 'Parking space', 'Safe Zone'
				gta.factory r
				continue

			when 'Light', 'Decal', 'Neon'
				continue

			when 'Block', 'Surface', 'Door'
				x = Math.floor r.x / gta.chunksize
				y = Math.floor r.y / gta.chunksize
			else
				x = Math.floor r.x / gta.chunkunits
				y = Math.floor r.y / gta.chunkunits

		hash = "#{x},#{y}"

		gta.hashes.push hash if -1 is gta.hashes.indexOf hash

		c = @raws[hash] or @raws[hash] = []
		
		gta.idpoolofprops r
		c.push r


	console.log "lowest activator is #{Activator::idpool}"

	gta.parkingspacespass()
	gta.walkspass()
	gta.safezonespass()

	true


gta.idpoolofprops = (props) ->
	if gta.activators[props.type]
		Activator::idpool = Math.min Activator::idpool, props.id

	1

gta.factory = (props) ->
	switch props.type
		# in nosj
		when 'Block', 'Surface' then new Block props
		when 'Door' then new Door props

		when 'Entity' then new Entity props
		when 'Walk' then new Walk props
		when 'Drive' then new Drive props
		when 'Parking space' then new ParkingSpace props
		when 'Safe Zone' then new SafeZone props
		
		when 'Table' then new Activator props
		when 'Desk' then new Activator props
		when 'Chair' then new Activator props
		when 'Couch' then new Activator props

		# Activators
		when 'Lab Freezer' then new LabFreezer props
		when 'Vacuum Oven' then new VacuumOven props
		when 'Incubator' then new Incubator props
		when 'Generator' then new Generator props
		when 'Worklight' then new Worklight props
		when 'Terminal' then new Terminal props
		when 'Teleporter' then new Teleporter props

		# civil Activators
		when 'ATM' then new ATM props
		when 'Vending Machine' then new VendingMachine props

		# containers
		when 'Dumpster' then new Dumpster props

		when 'Pickup' then new Pickup props

		when 'M9', 'M1911', 'MP412 REX', 'FN 57', 'Compact 45', '.44 Magnum', 'Desert Eagle', 'JS2', 'UMP', 'Groza-1', 'Groza-4', 'Magpul PDR', 'G36C', 'M4A1', 'AS Val', 'AK-12', 'AN-94', 'AEK-971', 'HK416', 'M16A4', 'SCAR-H', 'Mare\'s Leg', 'SPAS-12', 'SKS', 'SVD-12', 'Mk 11', 'Scout Elite', 'M40A5', 'Intervention', 'RPG'
			new Pickup props

		when 'Shank', 'Kitchen Knife', 'Combat Knife', 'Carbon Knife', 'Machete', 'Dragon Knife'
			new Pickup props

		else
			console.error "unknown visual type `#{props.type}`"

gta.factoryy = (props) ->
	switch props.model
		when 'M9', 'M1911', 'MP412 REX', 'FN 57', 'Compact 45', '.44 Magnum', 'Desert Eagle', 'JS2', 'UMP', 'Groza-1', 'Groza-4', 'Magpul PDR', 'G36C', 'M4A1', 'AS Val', 'AK-12', 'AN-94', 'AEK-971', 'HK416', 'M16A4', 'SCAR-H', 'Mare\'s Leg', 'SPAS-12', 'SKS', 'SVD-12', 'Mk 11', 'Scout Elite', 'M40A5', 'Intervention', 'RPG'
			new Gun props, gta.weps[ props.model ]

		when 'Shank', 'Kitchen Knife', 'Combat Knife', 'Carbon Knife', 'Machete', 'Dragon Knife'
			new Melee props, gta.weps[ props.model ]

		when 'Hands'
			new Hands props

		when 'Blue gloves'
			new BlueGloves props

		else
			console.error "unknown pickup type `#{props.type}`"

gta.weigh = (weights, array) ->
	weigh =
		weighted: []
		total: eval weights.join '+'
		produce: -> @weighted[Math.floor Math.random() * @total]
	
	cur = 0
	while cur < array.length
		for i in [0..weights[cur]-1 ]
			weigh.weighted[weigh.weighted.length] = array[cur]
		cur++

	weigh

gta.drop = (from, reroll) ->
	return

	# return unless from.type is 'Zombie'

	# rarity = gta.weighted.produce()
	# array = gta.drops[rarity]
	# i = Math.floor Math.random() * array.length
	# item = array[i]

	# console.log "dropping #{rarity} item: `#{item}`"

	# props = model: item, x: from.props.x, y: from.props.y, z: 64# , rarity: rarity
	# new Pickup props

	true

gta.loot = (from) ->

	true

gta.parkingspacespass = ->
	console.log 'parkingspacespass'

	for h in gta.hashes
		ch = h.split ','
		nearest = gta.nearestparkingspacesbych[h] = []

		for i, p of gta.parkingspaces
			nearest.push v: p, range: Math.hypot ch[0]*gta.chunkunits-p.props.x, ch[1]*gta.chunkunits-p.props.y

		nearest.sort (a,b) -> if a.range < b.range then return -1 else 1

		# console.log a.range for nearest

gta.walkspass = ->
	w.preprocess() for i, w of gta.walks

	console.log "walkspass preprocessed #{gta.walks.length}*#{gta.walks.length} walks"

	0

gta.safezonespass = ->
	s.preprocess() for i, s of gta.safezones

	console.log "safezonespass"

	0

class Session
	constructor: (@id, @ws) ->
		console.log "accepted ply ##{@id}"
		
		@in = {}
		@out = {}

		@bubbles = []

		@take = -1

		@outed = 0

		@last = Date.now()
		@delta = 0

		@removes = []

		@visuals = []

		@ply = new Player this

		@bubbles.push "#{gta.sessions.length} players on server"

		# @bubbles.push "GTA2.0 Open Alpha"

		for ses in gta.sessions
			ses.bubbles.push 'Player joined our world. Diablo\'s minions grow stronger.'

		;

	read: (text) ->

		return if @ply.dead

		@delta = Date.now() - @last
		@last = Date.now()

		gta.stats.bytesin += Buffer.byteLength text

		obj = JSON.parse text

		if 		parseFloat obj[0] is NaN or
				parseFloat obj[1] is NaN or
				parseFloat obj[2] is NaN or
				parseFloat obj[3] is NaN

			console.log 'in coords has NaN'.yellow
			return

		@in = obj[4] if obj[4]?

		# console.log "debug : @in.CAR " if @in.CAR?

		driving = @ply.car? and not @ply.passenger

		@ply.pose obj if not @in.CAR?
		
		@ply.car?.pose @in.CAR or obj if driving 

		@visuals = []
		@visuals = @visuals.concat c.visuals for c in @ply.chunks

		@passive()
		@action()

		@take = gta.frame


		true

	step: ->
		@mission?.step()

		# return
		
		if @ply.at? and not @mission? and not @t

			a = this
			cb = ->
				console.log a.id
				return if a.closed
				a.mission = new gta.missions.Hotline a
				a.t = 0
				return
			@t = setTimeout cb, 7000

		0

	passive: ->
		ignores = []
		ignores.push c.v for id, c of @ply.cards

		`CAT: //`
		if u = @ply.find 'Pickup', @visuals, 0, 15, false, ignores

			`break CAT` if @ply.cards[u.id]?

			@out.CARDS = [] if not @out.CARDS?

			@ply.cards[u.id] = v: u, time: Date.now()

			@out.CARDS.push id: u.id, name: u.props.model

		t = Date.now()

		for id, c of @ply.cards
			x = Math.abs c.v.props.x - @ply.props.x
			y = Math.abs c.v.props.y - @ply.props.y

			range = Math.hypot x, y
			if range <= 35
				c.time = t
			else
				continue unless c.time < t-2000
				@out.RMCARDS = [] if not @out.RMCARDS?
				@out.RMCARDS.push id
				delete @ply.cards[id]

		0

	action: ->
		# if @take is gta.frame
			# console.log "we already taken for this frame. ignoring".red

		if @in.BLEH? and @ply.car? # weve-shut-the-door thing

			at = @ply.at

			@ply.at.withdraw @ply
			
			# this fixes ch.beyond
			@ply.at = at

			car = @ply.car

			car.acknowledged = true

			car.state 'l', 1

		#

		if @in.USE? and @take isnt gta.frame

			# The Finding

			cars = @visuals.filter (v) -> 'Car' is v.type
			cardoors = []
			cardoors = cardoors.concat c.doors for c in cars

			# console.log "we collected #{cardoors.length} car doors"

			`CAT: //`
			if cardoor = @ply.find 'Car door', cardoors, 8, 12

				car = cardoor.car

				if cardoor.seat?
					@bubbles.push 'Someone\'s sitting here'

					`break CAT`

				if car.owner? and car.owner isnt @ply
					@bubbles.push 'It\'s locked'

					`break CAT`

				if car.props.owners?
					@bubbles.push "It\'s locked, it seems to belong to #{car.props.owners}"

					`break CAT`

				gta.world.DestroyBody @ply.body

				people = (car.doors.slice(0).filter (e) -> e.seat?).length

				cardoor.seat = @ply
				@ply.cardoor = cardoor

				@ply.passenger = cardoor.index > 0

				car.enter @ply

				@bubbles.push "(There are #{people} others in this car.)" if people

				@ply.state 'yc', i:car.id, r:car.props.r, f: 'right' is cardoor.door.side

				xx = parseFloat cardoor.props.xx.toFixed gta.reduce
				yy = parseFloat cardoor.props.yy.toFixed gta.reduce

				@ply.state 'cd', i:parseInt(cardoor.index), xx:xx, yy:yy

				# at = @ply.at
				# @ply.at.withdraw @ply
				
				# this fixes ch.beyond
				# @ply.at = at

				@ply.hidden = true

			else if door = @ply.find 'Door', @visuals, 8, 15, true
				to = door.vjson.to

				# Enter Interior
				if not @ply.props.interior?
					intr = gta.intrs[to] or new Interior to
					
					@out.INTR = to
					@out.INTRSTYLE = door.vjson.style
					@ply.props.interior = to

					filter = @ply.fixture.GetFilterData()
					filter.categoryBits = gta.masks.introrganic
					filter.maskBits = gta.masks.intrsolid | gta.masks.introrganic
					@ply.fixture.SetFilterData filter

					@ply.state 'intr', 1
					@ply.intrstamp = gta.frame

					for ply in @ply.at.subscribers
						ply.ses.removes.push @ply.id if ply.props.interior isnt to

					c.unsubscribe @ply for c in @ply.chunks
					
					@ply.chunks = []
					@ply.stamps = []
					@ply.at.withdraw @ply

					door.displace @ply
					@out.TP = [@ply.props.x, @ply.props.y]

					@ply.grid @ply.update()

					intr.occupants.push @ply

					@bubbles.push "Entering #{to}"

				# Exit Interior
				else if to is @ply.props.interior
					intr = gta.intrs[to]
					intr.leave @ply

					delete @ply.props.interior
					delete @ply.states.intr
					@ply.intrstamp = -1
					@out.OUTR = 1

					filter = @ply.fixture.GetFilterData()
					filter.categoryBits = gta.masks.organic
					filter.maskBits = gta.masks.solid | gta.masks.organic
					@ply.fixture.SetFilterData filter

					c.unsubscribe @ply for c in @ply.chunks
					@ply.chunks = []
					@ply.stamps = []
					@ply.at.withdraw @ply

					door.displace @ply, true
					@out.TP = [@ply.props.x, @ply.props.y]

					@ply.grid @ply.update()

					@bubbles.push "Leaving #{door.vjson.style} #{to}, come again"

			else if Activator = @ply.find 'Activator', @visuals, 8, 12
				q = Activator.use()
				@bubbles.push q

			else if container = @ply.find 'Container', @visuals, 8, 16
				q = container.use()
				@bubbles.push q

				# show the item cards

			else if mob = @ply.find 'Mob', @visuals, 8, 16

				q = mob.use()

				q = "Poncho man remains quiet" if mob.states.o is 2
				@bubbles.push "#{q}"

		# end @in.USE / <ENTER> key

		if @in.CARD?
			if @ply.cards[@in.CARD]?
				u = @ply.cards[@in.CARD].v

				if u.dtord is no
					@ply.pickup u
					# u.at.withdraw u
					u.dtor() # withdraws

				console.log "nice"

				delete @ply.cards[@in.CARD]

		if @in.SEL?
			if @ply.inventory[ @in.SEL ] and @ply.selected isnt @in.SEL
				@ply.state 'u', @in.SEL
				@ply.selected = @in.SEL
				@out.SEL = @ply.selected
				@ply.items[@ply.selected][0].select()
				
				# console.log "ses ##{@id} sels #{@in.SEL}"

		if @in.EXITCAR? and @ply.car?

			# when exiting, gta2.0 sends last car pos as Object
			# @ply.car.pose @in.CAR if @in.CAR?

			cardoor = @ply.cardoor
			car = @ply.car

			@ply.car.exit @ply
			@ply.car = null

			@ply.hidden = false

			@ply.props.r = car.props.r
			@ply.props.x = cardoor.props.x
			@ply.props.y = cardoor.props.y

			@ply.reduce()

			# @out.TP = [ @ply.props.x, @ply.props.y ]

			@ply.at.putcheck @ply

			@ply.embody()

		if @in.T?
			if @take isnt gta.frame
				@ply.trigger()

		if @in.W? # walk
			@ply.state 'w', @in.W

		true

	close: ->
		@mission.cleanup() if @mission?

		@ply.car?.exit @ply

		c.unsubscribe @ply for c in @ply.chunks

		@ply.at?.withdraw @ply

		# @ply.die()

		gta.intrs[ @ply.props.interior ].leave @ply if @ply.props.interior?

		@ply.dtor()

		@closed = true

		for ses in gta.sessions
			ses.bubbles.push 'Player left'

		true

	send: (text) ->
		bytes = Buffer.byteLength text

		gta.stats.bytesout += bytes
		@outed += bytes
		@ws.send text
		0

	pack: ->

		a = []
		for c, i in @ply.chunks
			c.observed = true
			a = a.concat c.pack @ply.stamps[i], @ply.props.interior, @ply.intrstamp
			@removes = @removes.concat c.removes if c.removes.length

		# a = a.concat @ply.interior.pack @ply.intrstamp if @ply.interior?

		@out.inventory = @ply.inventory if @ply.inventorystamp is gta.frame

		@out.removes = @removes if @removes.length
		@removes = []

		@bubbles = @bubbles.concat gta.globalbubbles
		@out.bubbles = @bubbles if @bubbles.length
		@bubbles = []

		# @out.f = gta.frame

		a.unshift @out if !! Object.keys(@out).length

		a = a.filter (e) -> e # remove falsy / nulls 

		@in = {}
		@out = {}

		return a

gta.chart = (x, y) ->
	hash = "#{x},#{y}"

	gta.chunks[hash] or new Chunk x, y


class Visual
	constructor: (@props) ->
		@props.x = 0 if not @props.x?
		@props.y = 0 if not @props.y?
		@props.r = 0 if not @props.r?
		@props.z = 64 if not @props.z?

		delete @props.interior if @props.interior is null # imperative for sql vis

		@type = 'Visual'

		@id = "v0"
		@at = null

		@states = {}
		@statestamp = -1

		@before = {}
		@reduced = {}
		@before.reduced = {}

		@served = false
		@stamp = gta.frame
		@hidden = false
		@volatile = false # to dtor in step when unobserved

		@dtord = no

		#
		
		@vjson = if @props.vjson?.length then JSON.parse @props.vjson else {}

		# @interior = gta.intrs[ @props.interior ] or null

		@state 'intr', 1 if @props.interior?
		
		# console.log "#{@type} is in #{@interior.name}" if @interior?

	state: (i, v) ->
		@states[i] = v
		@statestamp = gta.frame
		@refresh()
		true

	dtor: ->
		withdrew = @at?.withdraw this
		@dtord = yes

		# console.log "withdrew a #{@type}" if withdrew
		0

	hit: -> 0

	whole: -> 
		return null if @props.static
		[ @id, @states, @reduced.x, @reduced.y, @reduced.r, @reduced.z ]

	pack: ->
		return null if @props.static

		a = [ @id ]
		a[1] = @states if @statestamp is gta.frame
		a[2] = @reduced.x if @before.reduced.x isnt @reduced.x
		a[3] = @reduced.y if @before.reduced.y isnt @reduced.y
		a[4] = @reduced.r if @before.reduced.r isnt @reduced.r
		a[5] = @reduced.z if @before.reduced.z isnt @reduced.z

		@before = 			JSON.parse JSON.stringify @props
		@before.reduced = 	JSON.parse JSON.stringify @reduced

		a

	step: ->
		if @volatile and not @at?.observed
			console.log 'dtoring volatile'
			@dtor()

		###if @props.interior? and not gta.intrs[@props.interior]?
			return false
		else
			return true###

		0

	after: -> 'before'

	refresh: ->
		@stamp = gta.frame
		@at?.sleeping = false
		true

	collect: -> @stamp is gta.frame

	reduce: ->
		@reduced =
			x: parseFloat @props.x.toFixed gta.reduce
			y: parseFloat @props.y.toFixed gta.reduce
			r: parseFloat @props.r.toFixed gta.reduce
			z: @props.z
		true

	pose: -> return

	update: ->
		@stamp = gta.frame

		travel = @rechunk()

		@at.sleeping = false

		return travel

	rechunk: ->
		cx = Math.floor @props.x / gta.chunkunits
		cy = Math.floor @props.y / gta.chunkunits

		travel = gta.chart cx, cy

		moved = @at isnt travel

		# redesign out of bounds / ses.removes system

		if moved
			@served = false
			
			if @at? # for first rechunk
				for ply in @at.subscribers
					ply.ses.removes.push @id if travel.beyond ply.at

					# todo:
					# stacktrace: Mob.pose, Mob.Visual.update, Mob.Visual.rechunk, Chunk.beyond
					# rare crash where ply.at is null

				@at.withdraw this, true

			@at = travel
			@at.put this if not @hidden

		moved: moved, cx: cx, cy: cy

	find: (target, visuals, reach, r, ethereal, ignores) ->

		targets = Array.isArray target

		filtered = visuals.filter (v) ->
			if targets then v.type in target else v.type is target

		probe =
			x: @props.x
			y: @props.y

		if reach
			probe.x = probe.x + reach * Math.cos @props.r - (Math.PI/2)
			probe.y = probe.y + reach * Math.sin @props.r - (Math.PI/2)

		for v in filtered
			continue if v is this
			continue if ignores? and ignores.indexOf(v) isnt -1
			continue if v.props.interior isnt @props.interior and not ethereal

			continue if v.dead # lol

			x = Math.abs v.props.x - probe.x
			y = Math.abs v.props.y - probe.y

			range = Math.hypot x, y
			return v if range <= r

		null

	beginContact: (v) ->
		# console.log "#{@id} touched #{v.id}"
		0

	postSolve: (v, n) ->
		# console.log "impulse is #{n}"
		0

class Player extends Visual # todo extends Mob / Man
	constructor: (@ses) ->
		super {}

		@type = 'Player'

		@id = "p#{@ses.id}"

		@cards = []

		@chunks = []
		@stamps = []
		@intrstamp = -1

		@statestamp = -1

		@car = null
		@inventory = {}
		@inventorystamp = -1
		@items = {}
		@selected = null

		@recoil = 0

		@health = 100
		@kill = false
		@dead = false

		skin = ['wh','wh','wh','gl','bl'][ Math.floor Math.random() * 5 ]
		feet = ['lo', 'sn', 'al', 'dr'][ Math.floor Math.random() * 4 ]
		legs = ['je', 'de', 'kh'][ Math.floor Math.random() * 3 ]
		body = ['po', 'sw', 'bo', 'pa', 'sh', 'co'][ Math.floor Math.random() * 6 ] 
		hair = ['br'][ Math.floor Math.random() * 1 ]

		hair = 'Bl' if skin is 'bl' 					# black men have black hair
		feet = 'dr' if legs is 'kh' and feet is 'lo'	# dress shoes when trying loafers /w khaki (bad contrast in brown shoes/pants)
		skin = 'gl' if skin is 'bl'	and body is 'po'	# become white when black /w poncho
		hair = 'ph' if body is 'po'						# poncho hood
		legs = 'je' if body is 'po' and legs is 'kh'	# jeans when trying khaki /w poncho (its too brown)
		feet = 'sn' if body is 'po' and feet is 'dr'	# sneakers when trying dress shoes /w poncho (dress shoes too nice for ponchoman)
		
		@state 'o', "#{skin}#{feet}#{legs}#{body}#{hair}"
		@ses.out.OUTFIT = @states.o
		@parts = []
		@parts.push skin, feet, legs, body, hair

		@pickup props: model: 'Hands'
		@pickup props: model: 'Blue gloves'
		@pickup props: model: 'M9'
		@pickup props: model: 'UMP'
		@pickup props: model: 'Magpul PDR'
		@pickup props: model: 'AK-12'
		@pickup props: model: 'Shank'

		spawns = [
			[-313, 594, -1.5, 67]
			[-522, 361, -4.7, 67]
			[-197, 492, -1.6, 67]
			[-243, 739, -1.0, 67]
			[-525, 728, -5.2, 67]
		]

		s = spawns[Math.floor Math.random() * spawns.length ]
		@pose [s[0], s[1], s[2], s[3]] # calls @grid @update()
	
		@ses.out.TP = [@props.x, @props.y, @props.z]

		# @grid @update()

		@inventory['Hands']++ # make that two
		
		# @pickup props: type: 'JS2'

		setTimeout =>
			@state 'scratch', 1
		, 500

		@embody()

		# @reduce()
		;

	# override
	dtor: () ->
		if @body?
			gta.world.DestroyBody @body if @body?
			@body = null

		super()
		1

	embody: ->
		@bd = new box2d.Dynamics.b2BodyDef()
		@bd.type = box2d.Dynamics.b2Body.b2_dynamicBody
		#new box2d.b2Vec2 300 / gta.scaling, 300 / gta.scaling

		@circleShape = new box2d.Collision.Shapes.b2CircleShape 10 / gta.scaling

		fd = new box2d.Dynamics.b2FixtureDef
		fd.shape = @circleShape
		fd.density = 1
		fd.filter.categoryBits = gta.masks.organic
		fd.filter.maskBits = gta.masks.solid | gta.masks.organic

		@bd.position.Set @props.x, @props.y
		@body = gta.world.CreateBody @bd
		@body.SetUserData this
		@fixture = @body.CreateFixture fd
		1

	# override
	step: ->
		super()

		@recoil -= 0.075 if @recoil > 0

		@recoil = 0 if @recoil < 0

		@items[@selected][0].step() if @selected?

		if @body?
			@body.SetPosition new box2d.Common.Math.b2Vec2 @props.x / gta.scaling, @props.y / gta.scaling

		@die() if @kill

		1

	# override
	after: ->
		delete @states.g # unshoot
		delete @states.s # unslash
		delete @states.h # unhit
		delete @states.yc # your car
		delete @states.cd

		delete @states.scratch
		1

	trigger: ->
		if @selected?
			type = @items[@selected][0].type

			return if @car? and (type is 'Gun' or type is 'Melee')

			@items[@selected][0].use()

		1

	pickup: (r) ->
		r.props.type = 'Pickup'

		name = r.props.model
		has = @inventory[name]?

		item = gta.factoryy r.props
		item.owner = this

		if has
			@inventory[name]++
			@items[name].push item
		else
			@inventory[name] = 1
			@items[name] = [ item ]

		@inventorystamp = gta.frame

		1

	# override
	whole: -> super()

	# override
	#pack: ->
		#a = super()
		
		#return a

	# override
	pose: (o) ->
		
		@props.x = o[0] if o[0]?
		@props.y = o[1] if o[1]?
		@props.r = o[2] if o[2]?
		@props.z = o[3] if o[3]?

		@reduce()

		con = 	@before.reduced.x isnt @reduced.x or
				@before.reduced.y isnt @reduced.y or
				@before.reduced.r isnt @reduced.r or
				@before.reduced.z isnt @reduced.z

		return unless con

		@grid @update()

		0

	grid: (travel) ->
		if travel.moved

			old = @chunks.slice 0
			@chunks = []
			@stamps = []

			for y in [1..3]
				for x in [1..3]
					sx = gta.surround[y][x][0] + travel.cx
					sy = gta.surround[y][x][1] + travel.cy
					chart = gta.chart sx, sy
					chart.observed = true
					@chunks.push chart
					chart.subscribe this
					@stamps.push if old.indexOf(chart) is -1 then gta.frame else -1

			for c in old
				if @chunks.indexOf(c) is -1
					c.unsubscribe this
					@ses.removes.push v.id for v in c.visuals

					# low-priority todo:
					# record chunk hash of visual
					# send id of chunk to delete, instead of separate visuals

					# i mention of it here:
					# https://github.com/otse/GTA2.0/issues/24#issue-99421473

		1

	hit: (from, using, damage) ->
		return false if @dead or @kill

		dmg = 0

		if from.type is 'Zombie'
			@health -= 20
			@state 'h', 1 # hit
			@ses.out.h = true

		if using?.type is 'Gun'
			damage /= 2
			@health -= damage
			@state 'h', 1 # hit

		else if using?.type is 'Melee'
			damage /= 2
			@health -= damage
			@state 'h', 1 # hit

		r = Math.floor Math.random() * 8
		new Decal decal: "b#{r}", x: @props.x, y: @props.y
		
		@checkup from

		@ses.bubbles.push "Hit for #{damage.toFixed 2} down to #{@health.toFixed 2} HP"

		#@ses.out.HP = @health
		#@ses.out.DMG = damage
		1

	checkup: (from) ->
		if @health <= 0
			@kill = true

			if from.type is 'Player' and not from.bandit
				if not @bandit
					from.bandit = true
					from.state 'outlaw', 1
					from.ses.out.OUTLAW = 1
					from.ses.bubbles.push 'You are now a bandit...'
				else
					from.ses.bubbles.push 'You killed a bandit player.'

		1

	die: ->
		return if @dead

		@kill = false
		@dead = true

		@state 'd', Math.floor Math.random() * 10

		gta.world.DestroyBody @body if @body?
		@body = null

		@ses.out.DEAD = true
		@ses.bubbles.push "You are ded. Reload page to respawn (temporary)"

		@dropall()

		1

	dropall: ->
		for n, a of @items
			for i in a
				continue if i.props.model is 'Hands'

				props = type: 'Pickup', model: i.props.model, x:@props.x, y:@props.y, z: 64
				props.interior = @props.interior if @props.interior
				new Pickup props
		1

class CarDoor
	constructor: (@car, @index, @door) -> 
		@props = 
			type: 'Car door'
			x: 0
			xx: 0
			y: 0
			yy: 0
			z: 0

		@type = 'Car door'

		@seat = null

		@pose()

	pose: (v) ->
		center = x: @car.stats.width / 2, y: @car.stats.height / 2
		center = x: @car.props.x, y: @car.props.y

		r = @car.props.r

		x = @car.props.x + @door.x
		y = @car.props.y - @door.y

		newX = center.x + (x-center.x)*Math.cos(r) - (y-center.y)*Math.sin(r);
		newY = center.y + (x-center.x)*Math.sin(r) + (y-center.y)*Math.cos(r);

		x = @car.props.x + @door.x/4
		xx = center.x + (x-center.x)*Math.cos(r) - (y-center.y)*Math.sin(r);
		yy = center.y + (x-center.x)*Math.sin(r) + (y-center.y)*Math.cos(r);

		@props.x = newX
		@props.y = newY
		@props.xx = xx
		@props.yy = yy

		1


class Car extends Visual
	increment: 0
	decrement: 0
	carpool: {}

	constructor: (props) ->
		super props

		# console.log 'car ctor'

		@type = 'Car'

		props.id = --Car::decrement if not @props.id?

		@id = "c#{props.id}"

		if Car::carpool.hasOwnProperty props.id
			console.log "CARPOOL: Can't spawn a #{props.color} #{props.model} with id ##{props.id}; in carpool."
			return

		Car::carpool["#{props.id}"] = props.id

		@stats = gta.cars[props.model]

		@doors = []

		if @stats.doors?
			@doors.push new CarDoor this, i, d for i, d of @stats.doors

		@state 'm', props.model
		@state 'c', props.color or @stats.colors?[0]
		# @state 'l', 0

		@props.z = 64

		@health = 1000

		@acknowledged = false # awful fix to interpolation

		@driver = null

		@speed = 0

		@reduce()
		
		@rechunk()

		# for late chunk admission
		@update()
		# @at.sleeping = false

		@embody()

	# override
	dtor: ->
		has = Car::carpool.hasOwnProperty @props.id
		delete Car::carpool[@props.id] if has

		@mission?.callback this, 'dtor'

		gta.world.DestroyBody @body if @body?
		@body = null

		super()
		true

	embody: ->
		@bd = new box2d.Dynamics.b2BodyDef()
		@bd.type = box2d.Dynamics.b2Body.b2_staticBody
		@bd.position.Set @props.x / gta.scaling, @props.y / gta.scaling

		@polygonShape = new box2d.Collision.Shapes.b2PolygonShape
		@polygonShape.SetAsBox (@stats.sizew / 2) / gta.scaling, (@stats.sizeh / 2) / gta.scaling

		fd = new box2d.Dynamics.b2FixtureDef
		fd.shape = @polygonShape
		fd.filter.categoryBits = gta.masks.solid
		fd.filter.maskBits = -1

		@body = gta.world.CreateBody @bd
		@body.SetAngle @props.r
		@body.SetUserData this
		@fixture = @body.CreateFixture fd

		true

	beginContact: (v) ->
		# console.log "#{@id} touched #{v.id}"
		0

	postSolve: (v, n) ->
		#console.log "Car #{@props.model} hit #{v.type} for #{n}"
		
		if v.type is 'Mob' # or v.type is 'Zombie'
			if @speed > .15
				v.hit this, null, 100
			else if @speed > .1
				v.hit this
		0

	# override
	whole: -> super()

	# override
	#pack: ->
		#a = super()
		
		#return a

	# override
	step: ->
		super()

		return if @dtord is yes

		if @driver? and @driver?.ses.in.b?

			flag = zeroorone @driver.ses.in.b

			@state 'b', flag if flag isnt @states.b 

		@body.SetPosition new box2d.Common.Math.b2Vec2 @props.x / gta.scaling, @props.y / gta.scaling
		@body.SetAngle @props.r
		true

	hit: (from, using, damage) ->
		if using.type is 'Gun'
			@state 'h', Math.floor Math.random() * 9

		true

	# override
	after: ->
		delete @states.h
		# delete @states.d
		# delete @states.b

		true

	# override
	pose: (o) ->

		return unless @acknowledged

		if @driver?
			x = o[0] or @props.x
			y = o[1] or @props.y
			
			travel = Math.hypot @props.x-x, @props.y-y
			
			delta = Math.min @driver.ses.delta, 100
			
			x = parseFloat x.toFixed 1
			y = parseFloat y.toFixed 1
			@speed = travel/delta 

			# console.log "#{travel.toFixed 2} of #{@props.x.toFixed 1},#{@props.y.toFixed 1} to #{x},#{y} : #{@speed}"
		else
			@speed = 0

		@props.x = o[0] if o[0]?
		@props.y = o[1] if o[1]?
		@props.r = o[2] if o[2]?

		d.pose() for d in @doors

		@reduce()

		@update()

		0

	enter: (ply) ->

		if not ply.passenger
			@acknowledged = false
			@driver = ply

		ply.car = this

		@speed = 0
		0

	exit: (ply) ->

		if not ply.passenger
			@driver = null
			@state 'b', 0 # 'braking'

		ply.cardoor.seat = null

		ply.cardoor = null

		people = (@doors.slice(0).filter (e) -> e.seat?).length

		@state 'l', 0 if not people

		@speed = 0
		0


class Pickup extends Visual
	increment: 0
	decrement: 0

	constructor: (props) ->
		super props

		@type = 'Pickup'

		# rework this
		###if not props.rarity?
			for k, v of gta.drops
				if v.indexOf(props.type) isnt -1
					@props.rarity = k
					break###

		props.x += Math.random()
		props.y += Math.random()

		props.id = Pickup::decrement-- if not props.id?

		@id = "u#{props.id}"

		@state 'model', props.model

		@embody()

		@reduce()

		unless @props.static
			@rechunk()
			
			# for late chunk admission
			@update()

		@props.static = false

		# @at.sleeping = false

	# override
	dtor: ->
		gta.world.DestroyBody @body
		@body = null

		super()
		true

	embody: ->
		@bd = new box2d.Dynamics.b2BodyDef()
		@bd.type = box2d.Dynamics.b2Body.b2_dynamicBody
		@bd.position.Set @props.x / gta.scaling, @props.y / gta.scaling

		@circleShape = new box2d.Collision.Shapes.b2CircleShape 4 / gta.scaling

		fd = new box2d.Dynamics.b2FixtureDef
		fd.shape = @circleShape
		fd.density = 1

		if not @props.interior
			fd.filter.categoryBits = gta.masks.items
			fd.filter.maskBits = gta.masks.solid | gta.masks.items
		else
			fd.filter.categoryBits = gta.masks.intritems
			fd.filter.maskBits = gta.masks.intrsolid | gta.masks.intritems

		@body = gta.world.CreateBody @bd
		@body.SetUserData this
		@fixture = @body.CreateFixture fd

		@body.SetLinearDamping 0.5
		@body.SetAngularDamping 0.5
		true

	
	# override
	whole: -> super()

	# override
	#pack: ->
		#a = super()
		
		#return a

	# override
	pose: ->
		pos = @body.GetPosition()
		@props.x = pos.x * gta.scaling
		@props.y = pos.y * gta.scaling

		@props.r = @body.GetAngle()

		@reduce()

		con = 	@before.reduced.x isnt @reduced.x or
				@before.reduced.y isnt @reduced.y or
				@before.reduced.z isnt @reduced.z

		@update() if con

		true

	# override
	step: ->
		console.log "we are dtord" if @dtord

		return if @dtord

		@pose()
		true


class Item
	constructor: (@props) ->
		@type = 'Item'

		@owner = null

	select: -> true
	step: -> true
	use: -> true

class Hands extends Item
	constructor: (props) ->
		super props

		@type = 'Hands'

	select: -> true
	step: -> true
	use: -> true

class BlueGloves extends Item
	constructor: (props) ->
		super props

		@type = 'Blue gloves'

		@equipped = false

	select: ->
		states = @owner.states

		@skin ?= states.o.substr 0, 2

		console.log @skin

		@equipped = not @equipped

		if @equipped
			states.o = "su#{states.o.substr 2}"

			@owner.ses.bubbles.push 'You look like you\'re going to rob a bank!'
		else
			states.o = "#{@skin}#{states.o.substr 2}"

		@owner.refresh()

		1

	step: -> 1
	use: -> 1

class Gun extends Item
	constructor: (props, @model) ->
		super props

		@type = 'Gun'
		
		@fired = gta.frame + @model.firerate

	# override
	select: ->
		@fired = gta.frame + @model.firerate
		true

	# override
	use: ->
		super()

		return unless gta.frame >= @fired

		# todo: cleanup this function it's a tad crowded

		@fired = gta.frame + @model.firerate

		@owner.recoil += 0.15
		@owner.recoil = 1 if @owner.recoil > 1
		recoil = 1 + @owner.recoil * @model.recoil * 3

		base = .1 # minimum spread
		spread = (1-@model.accuracy) * Math.random() * base * recoil

		r = @owner.props.r
		if Math.random() < .5
			r -= spread
		else
			r += spread

		reach = @model.range * (448 * 2)

		origin = x: @owner.props.x, y: @owner.props.y
		probe =
			x: origin.x + reach * Math.cos r - (Math.PI/2)
			y: origin.y + reach * Math.sin r - (Math.PI/2)

		@owner.ses.out.LINE = x: probe.x, y: probe.y


		decal =
		switch @model.type
			when 'Shotgun' then 'c1'
			when 'Handgun' then 'c2'
			when 'SMG' then 'c3'
			when 'Carbine' then 'c3'
			when 'AR' then 'c4'
			when 'Sniper' then 'c5'
			when 'DMR' then 'c5'
			else
				null

		if decal?
			new Casing
				decal: decal
				x: origin.x
				y: origin.y
				eject: @owner.props.r - Math.PI/2 - 0.8
				interior: @owner.props.interior or null

		# lexical vars for cb-closure
		catchers = []

		cb = (x) ->
			v = x.m_body.GetUserData()

			return unless v? # ??...

			x = Math.abs v.props.x - origin.x
			y = Math.abs v.props.y - origin.y
			range = Math.hypot x, y

			switch v.type
				when 'Block', 'Mob', 'Zombie', 'Player', 'Car';
				else return

			catchers.push v: v, range: range

			true

		p1 = @owner.body.GetPosition()
		p2 = new box2d.Common.Math.b2Vec2 probe.x / gta.scaling, probe.y / gta.scaling

		gta.world.RayCast cb, p1,p2

		catchers.sort (a,b) -> if a.range < b.range then return -1 else 1

		for o in catchers
			continue if o.v.props.interior isnt @owner.props.interior

			break if o.type is 'Block'

			if o.range <= reach * .25 # maximum damage
				damage = @model.damage
			else
				dropoff = @model.damage * (o.range-reach)/-reach
				damage = Math.max dropoff, @model.damage * .6

			o.v.hit @owner, this, damage

			break

		@owner.state 'g', 1
		@owner.ses.out.g = 1

		true

class Melee extends Item
	constructor: (props, @model) ->
		super props

		@type = 'Melee'

		@swung = gta.frame

		@impact = true

	# override
	select: ->
		@swung = gta.frame

		1

	# override
	step: ->
		@attack() if gta.frame >= @swung-3 and not @impact

		1

	attack: ->

		@impact = true

		v = @owner.find ['Player', 'Mob', 'Zombie', 'Car'], @owner.ses.visuals, 8, 16

		v?.hit @owner, this, @model.damage

		1

	# override
	use: ->
		super()

		return unless gta.frame >= @swung

		@swung = gta.frame + @model.firerate

		@impact = false

		@owner.state 's', 1
		# @owner.ses.out.s = 1

		1

class Decal extends Visual
	constructor: (props) ->
		super props

		@type = 'Decal'

		@id = "d#{gta.decalpool++}"
		
		@state 'decal', props.decal

		@spawn = Date.now()

		@reduce()

		@rechunk()

	# override
	dtor: ->
		super()
		# gta.world.DestroyBody @body
		true

	# override
	step: ->
		if @spawn < Date.now()-3000
			@dtor()
			return

		@pose()
		true

	# override
	whole: -> super()

	# override
	#pack: ->
		#a = super()
		
		#return a

	# override
	pose: ->
		@reduce()

		con = 	@before.reduced.x isnt @reduced.x or
				@before.reduced.y isnt @reduced.y or
				@before.reduced.r isnt @reduced.r or
				@before.reduced.z isnt @reduced.z

		@update() if con

		true

class Casing extends Decal
	constructor: (props) ->

		super props

		props.z = 64
		props.r = Math.random() * Math.PI

		ejectat =
			x: props.x + 8 * Math.cos props.eject + (Math.random()*.1)
			y: props.y + 8 * Math.sin props.eject + (Math.random()*.1)

		props.x = ejectat.x
		props.y = ejectat.y

		# x = ejectat.x + .00001 * Math.cos props.eject #- (Math.PI/2)
		# y = ejectat.y + .00001 * Math.sin props.eject #- (Math.PI/2)

		spin = Math.random() * 60
		spin = -spin if Math.random() < .5

		@state 'spin', spin

		@reduce()

		@rechunk()


class Block # pseudo vis
	constructor: (@props) ->
		@type = 'Block'

		@props.x += .5
		@props.y += .5

		@props.x *= 64
		@props.y *= 64

		if @props.z is 1 and @props.type is 'Block' # or
		   # @props.z is -1 and @props.type is 'Surface'
			@embody()

	hit: -> 0

	step: -> return
	pack: -> null
	collect: -> no
	whole: -> null
	after: -> return

	dtor: ->
		gta.world.DestroyBody @body if @body?
		true

	embody: ->
		@bd = new box2d.Dynamics.b2BodyDef()
		@bd.type = box2d.Dynamics.b2Body.b2_staticBody
		@bd.position.Set @props.x / gta.scaling, @props.y / gta.scaling

		@polygonShape = new box2d.Collision.Shapes.b2PolygonShape
		@polygonShape.SetAsBox 32 / gta.scaling, 32 / gta.scaling

		fd = new box2d.Dynamics.b2FixtureDef
		fd.shape = @polygonShape
		fd.filter.categoryBits = gta.masks.solid
		fd.filter.maskBits = -1

		@body = gta.world.CreateBody @bd
		@body.SetUserData this
		@fixture = @body.CreateFixture fd
		true

	beginContact: -> 0
	postSolve: -> 0

class Door # pseudo visual
	constructor: (@props) ->
		@type = 'Door'

		@vjson = if not @props.vjson? then {} else JSON.parse @props.vjson 

		if not @vjson.to?
			@type = 'Poorly scripted door' # this works tho ._.

		@props.r = 0 if not @props.r?

		rotations = [[0, 31.95], [31.95, 0], [0, -31.95], [-31.95, 0]]

		@props.x += .5
		@props.y += .5

		@props.x *= 64
		@props.y *= 64

		@props.x += rotations[@props.r][0]
		@props.y += rotations[@props.r][1]
		;

	displace: (ply, out) ->
		
		inside = [[0, 16], [16, 0], [0, -16], [-16, 0]]
		outside = [[0, -16], [-16, 0], [0, 16], [16, 0]]

		rotations = if out then outside else inside

		x = @props.x
		y = @props.y

		x += rotations[@props.r][0]
		y += rotations[@props.r][1]

		ply.props.x = x
		ply.props.y = y

		ply.reduce()

		true

	dtor: -> return
	step: -> return
	pack: -> null
	collect: -> null
	whole: -> null
	after: -> return

class Interior
	constructor: (@name) ->
		console.log "making new interior: #{@name}"

		@occupants = []

		gta.intrs[@name] = this

		# WHERE x >= #{@ux} AND y >= #{@uy} AND x < #{@uex} AND y < #{@uey}

		###
		query = "SELECT * FROM `visuals` WHERE interior = \"#{@name}\""
		gta.db.query query, (err, rows) ->
			gta.factory r for r in rows
			return

		query = "SELECT * FROM `cars` WHERE interior = \"#{@name}\""
		gta.db.query query, (err, rows) ->
			new Car r for r in rows
			return
		###

		;

	dtor: ->
		console.log "dtor of interior"
		0

	leave: (@ply) ->
		i = @occupants.indexOf @ply
		@occupants.splice i, 1

		true

	step: ->
		if not @occupants.length
			@dtor()
			return false

		true

class Activator extends Visual
	idpool: 0

	constructor: (props) ->
		# console.log "Activator ##{props.id} of type #{props.type}"
		
		super props

		@type = 'Activator'

		props.id = --Activator::idpool if not props.id?

		@id = "m#{props.id}"

		@model = gta.activators[@props.type]

		@embody()

		@state 'type', props.type

		# @spawn = Date.now()

		@reduce()

		unless @props.static
			@rechunk()

			# for late chunk admission
			@update()
			# @at.sleeping = false
		else
			# console.log "#{props.type} is static"
			;
		;

	# override
	dtor: ->
		gta.world.DestroyBody @body if @body?
		@body = null
		super()
		true

	embody: ->
		@bd = new box2d.Dynamics.b2BodyDef()
		@bd.type = box2d.Dynamics.b2Body.b2_staticBody
		@bd.position.Set @props.x / gta.scaling, @props.y / gta.scaling

		@polygonShape = new box2d.Collision.Shapes.b2PolygonShape
		@polygonShape.SetAsBox (@model.sprite.width / 2) / gta.scaling, (@model.sprite.height / 2) / gta.scaling

		fd = new box2d.Dynamics.b2FixtureDef
		fd.shape = @polygonShape
		fd.filter.categoryBits = gta.masks.solid
		fd.filter.maskBits = -1

		@body = gta.world.CreateBody @bd
		@body.SetAngle @props.r
		@body.SetUserData this
		@fixture = @body.CreateFixture fd
		true

	# override
	step: ->
		# @pose()
		true

	# override
	whole: -> super()

	# override
	#pack: ->
		#a = super()

		#return a

	# override
	pose: ->
		# @reduce()

		# @update() if con

		true

	use: -> @props.type

class ATM extends Activator
	constructor: (props) ->
		super props

	# override
	use: ->
		"*Crrrtrr* (ATM Machine)"

class VendingMachine extends Activator
	constructor: (props) ->
		super props

	# override
	use: ->
		"*Sszzr* (Vending Machine)"

class LabFreezer extends Activator
	constructor: (props) ->
		super props

	# override
	use: ->
		"Lab Freezer"

class VacuumOven extends Activator
	constructor: (props) ->
		super props

	# override
	use: ->
		"Vacuum Oven"

class Incubator extends Activator
	constructor: (props) ->
		super props

		@bleepbep = yes

	# override
	use: ->
		"Incubator"

class Generator extends Activator
	constructor: (props) ->
		super props

		@on = off
		@reserve = 0

		@cable = new Cable

	# override
	use: ->
		"*Vbrrrr* (Generator)"

class Worklight extends Activator
	constructor: (props) ->
		super props

		@on = on

		@state 'o', 1

	# override
	use: ->
		@on = if @on then 0 else 1

		@state 'o', @on

		"*Vrzzzzmzmz* (Worklight)"

class Terminal extends Activator
	constructor: (props) ->
		super props

		@on = on

		# @state 'o', 1

	# override
	use: ->
		# @on = if @on then 0 else 1

		# @state 'o', @on

		"Terminal"

class Teleporter extends Activator
	constructor: (props) ->
		super props

		@on = on

		# @state 'o', 1

	# override
	use: ->
		# @on = if @on then 0 else 1

		# @state 'o', @on

		"Teleporter"

class Cable # extends Visual
	constructor: (props) ->
		# super props

		;

	embody: ->


		true

	nice: -> yes

class Dumpster extends Activator
	constructor: (props) ->
		super props

		@varrr = no

		# @state 'o', 1

	# override
	use: ->
		# @on = if @on then 0 else 1

		# @state 'o', @on

		"Dumpster"

class Chunk
	constructor: (@x, @y) ->

		# console.log "chunk ctor #{@x},#{@y}"

		@sleeping = true
		@stamp = gta.frame
		@expire = @stamp + gta.chunklife

		@observed = false
		@peekaboo = 0

		@firststep = true # used for mob spawning

		@intrs = {} # should be {}

		@subscribers = []

		@hash = "#{@x},#{@y}"

		@walks = gta.walksbych[ @hash ] or null
		@parkingspaces = gta.parkingspacesbych[ @hash ] or null
		@entities = gta.entitiesbych[ @hash ] or null

		# console.log "hash #{@hash} entitiesbych".red
		console.log "chunk #{@hash} has #{@entities.length} ents".red if @entities?

		@visuals = []
		# @solids = []

		@peds = 0

		@pedsbound = 0
		if @walks?
			for w in @walks
				@pedsbound += w.pedsbound
				w.pedsbound = 0

		# console.log "#{@pedsbound} pedestrians were already bound for chunk #{@hash}"
		
		gta.chunks[@hash] = this

		@removes = []

		@build = []
		@all = []
		@allstamp = -1

		@ux = @x * gta.chunkunits
		@uy = @y * gta.chunkunits
		@uex = @ux + gta.chunkunits
		@uey = @uy + gta.chunkunits

		@fetch()

		if gta.raws[@hash]?
			for r in gta.raws[@hash]
				s = JSON.parse JSON.stringify r # todo: maybe shallow-copy the array instead
				s.static = true
				v = gta.factory s
				@put v
				v.at = this
		;

	dtor: ->
		for v in @visuals.slice 0
			v.dtor()

		# s.dtor() for s in @solids
		true

	subscribe: (ply) ->
		i = @subscribers.indexOf ply
		@subscribers.push ply if i is -1
		true

	unsubscribe: (ply) ->
		i = @subscribers.indexOf ply
		@subscribers.splice i, 1 if i isnt -1
		true

	step: ->
		if gta.frame >= @expire
			@dtor()
			return false

		peekaboo = 0

		# if @firststep
			# for [0..5]
				# new Zombie x: @x*gta.chunkunits, y: @y*gta.chunkunits, z:64

		for i, o of @intrs
			if gta.intrs[i]? and o.peekaboo is 0
				o.peekaboo = 1

				if @entities?
					for e in @entities
						if e.props.interior and gta.intrs[e.props.interior]?
							e.event 'peekaboo'

			else if gta.intrs[i]?
				o.peekaboo = 2
			else if not gta.intrs[i]?
				o.peekaboo = 0

		if @observed and @peekaboo is 0
			@peekaboo = 1
		else if @observed
			@peekaboo = 2
		else if not @observed
			@peekaboo = 0

		# @peds = (@visuals.slice(0).filter (e) -> e.type is 'Mob').length

		# @congestion = @peds > 15

		limit = 2

		if @observed and @walks? and limit-@pedsbound > 0

			for [1..limit-@pedsbound]
				options = Walk::crossoversbych[ @hash ]

				narrowed = []

				for set in options
					c = gta.chunks[ set.from.hash ]
					continue if c? and c.observed
					narrowed.push set

				break if not narrowed.length

				link = random narrowed

				routines = ['Pedestrian']

				routines.push 'TakeABreak' if Math.random() < .33

				# subtype = 'Hitman' if Math.random() < .2

				new Mob
					type: 'Mob'
					# subtype: subtype
					routines: routines
					ch: @hash
					from: link.from.vjson.id
					to: link.to.vjson.id

		if @peekaboo is 1
			# console.log "peekaboo is 1 for #{@x}, #{@y}"

			if @parkingspaces?
				p.event 'peekaboo' for p in @parkingspaces

			if @entities?
				e.event 'peekaboo' for e in @entities


		for v in @visuals.slice 0
			continue if not v?
			continue if v.props.interior and not gta.intrs[v.props.interior]?

			v.step()

		true

	beyond: (chunk) ->
		o =
			x: Math.abs @x - chunk.x
			y: Math.abs @y - chunk.y
		
		o.x > 1 or o.y > 1
	
	fetch: ->
		chunk = this

		###
		query = "SELECT * FROM `cars` WHERE x >= #{@ux} AND y >= #{@uy} AND x < #{@uex} AND y < #{@uey} AND interior is NULL"
		gta.db.query query, (err, rows) ->
			new Car r for r in rows
			return

		# query = "SELECT * FROM `pickups` WHERE x >= #{@ux} AND y >= #{@uy} AND x < #{@uex} AND y < #{@uey}"
		# gta.db.query query, (err, rows) ->
		# 	new Pickup r for r in rows
		# 	return

		query = "SELECT * FROM `visuals` WHERE x >= #{@ux} AND y >= #{@uy} AND x < #{@uex} AND y < #{@uey} and interior is NULL"
		gta.db.query query, (err, rows) ->
			gta.factory r for r in rows
			return
		###
		
		true

	put: (v) ->
		@visuals.push v
		@reserveintr v
		true

	putcheck: (v) ->
		i = @visuals.indexOf v
		if i is -1
			@visuals.push v
			@reserveintr v
		true

	# use keep if vis isnt also being dtored
	withdraw: (v, keep) ->
		i = @visuals.indexOf v
		has = i > -1
		@visuals.splice i, 1 if has
		@removes.push v.id unless keep
		v.at = null # unless keep
		v.served = false
		has

	after: ->
		@sleeping = true

		if @observed
			@stamp = gta.frame
			@expire = @stamp + gta.chunklife

		@removes = []

		for v in @visuals.slice 0
			v.after()

		true

	reserveintr: (v) ->
		return unless v.props.interior?

		# console.log "#{v.type} is in interior #{v.props.interior}".green

		name = v.props.interior

		if not @intrs[name]?
			@intrs[name] = instance: null, all: [], build: [], peekaboo: 0

			# console.log "actual reserveintr by #{@hash} for `#{name}`; #{@intrs[name].all.length}".green

		true

	compile: ->
		@build = []

		o.build = [] for i, o of @intrs

		return if @sleeping

		# console.log "compiling #{@hash} at #{gta.frame}"

		for v in @visuals
			build = @build

			if intr = v.props.interior
				continue if not gta.intrs[intr]? # not very useful
				
				build = @intrs[intr].build

			if not v.served
				v.served = true
				build.push v.whole()
			else if v.collect()
				build.push v.pack()
				
		0

	whole: (intr) ->

		# if intr? and not @intrs[intr.name]?
			# console.log 'chunk does not house intr'
			# return []

		if @allstamp isnt gta.frame
			# console.log "serving #{@hash} whole at #{gta.frame}"

			@all = []
			@allstamp = gta.frame

			o.all = [] for i, o of @intrs

			for v in @visuals
				all = @all

				all = @intrs[k].all if k = v.props.interior

				v.served = true
				all.push v.whole()

		if intr? then @intrs[intr].all else @all

	pack: (stamp, intr, intrstamp) ->
		a = []

		a = if stamp is gta.frame then @whole() else @build

		if intr? and @intrs[intr]?
			a = a.concat if intrstamp is gta.frame then @whole intr else @intrs[intr].build

		a

class Entity extends Visual
	idpool: 0

	constructor: (props) ->
		super props

		@type = 'Entity'

		@props.static = false # hm

		@id = "e#{@props.id or @vjson.id or -1}"

		x = Math.floor @props.x / gta.chunkunits
		y = Math.floor @props.y / gta.chunkunits

		@hash = "#{x},#{y}"
		
		@categorize()

		@init()

	pack: -> null
	collect: -> no
	whole: -> null

	step: ->
		return unless super()

		console.log "#{@vjson.type} step".green if @props.interior

	init: ->
		switch @vjson.type
			when 'Vendor'
				@reservedid = Mob::ids++
		1

	categorize: ->
		gta.entities[@vjson.id] = this
		c = gta.entitiesbych[ @hash ] or gta.entitiesbych[ @hash ] = []
		c.push this
		0

	event: (e) ->
		return if @props.interior and not gta.intrs[@props.interior]?

		console.log "Entity event at #{@hash}".cyan

		if e is 'peekaboo'

			switch @vjson.type
				when 'Vendor'
					
					console.log "making vendor in intr #{@props.interior}".green

					vendor =
						id: @reservedid
						type: 'Mob'
						routines: ['Vendor']
						x: @props.x
						y: @props.y
						z: 64
						r: @vjson.r
						interior: @props.interior

					new Mob vendor

		0


class Drive extends Entity
	constructor: (props) ->
		super props

		@type = 'Drive'
		;

	categorize: ->
		gta.drives[@vjson.id] = this
		# c = gta.walksbych[ @hash ] or gta.walksbych[ @hash ] = []
		# c.push this
		0

	step: -> 0

class Walk extends Entity
	tweensbypairs: {}
	
	crossoversbych: {}

	pairhash: (a,b) -> "#{Math.min a.vjson.id, b.vjson.id},#{Math.max a.vjson.id, b.vjson.id}"
	
	gettweens: (a,b) -> Walk::tweensbypairs[ Walk::pairhash a,b ]


	constructor: (props) ->
		super props

		@type = 'Walk'

		@angletoid = []

		@tweensbylink = []

		@pedsbound = 0

		if not @vjson.id? or not @vjson.type? or not @vjson.links?
			console.log 'walk node is malformed'.yellow

	categorize: ->
		gta.walks[@vjson.id] = this
		c = gta.walksbych[ @hash ] or gta.walksbych[ @hash ] = []
		c.push this
		0

	step: -> 0

	preprocess: ->
		links = @vjson.links

		return unless links?

		# bake intermediate positions between links; aka tweens

		for i in links
			l = gta.walks[ i ]
			continue unless l?
			# continue unless @vjson.type is w.vjson.type

			pair = Walk::pairhash this, l

			tweens = Walk::tweensbypairs[ pair ] ?= []

			theta = Math.atan2 @props.y-l.props.y, @props.x-l.props.x

			x = Math.abs @props.x - l.props.x
			y = Math.abs @props.y - l.props.y

			for j in [1..10]
				range = j/10 * Math.hypot x, y

				tween =
					x: @props.x - range * Math.cos theta
					y: @props.y - range * Math.sin theta

				tweens.push tween

		# bake chunk refill / crossovers
		for i in links
			l = gta.walks[ i ]
			continue unless l?
			continue unless l.hash isnt @hash
			array = Walk::crossoversbych[ @hash ] ?= []
			array.push from: l, to: this

		# then bake angles

		for i in links
			l = gta.walks[ i ]
			continue unless l?

			theta = Math.atan2 @props.y-l.props.y, @props.x-l.props.x
			theta *= 180 / Math.PI

			d = parseFloat theta.toFixed 1

			@angletoid[i] = d

			# console.log "angle from #{@vjson.id} to id #{i} is #{d}"
		1

class SafeZone extends Entity
	constructor: (props) ->
		super props

		@type = 'Safe Zone'

		;

	step: -> 0

class ParkingSpace extends Entity
	constructor: (props) ->
		super props

		@type = 'Parking space'

		@reservedid = --Car::decrement

		@mission = null

		;

	step: -> 0

	categorize: ->
		gta.parkingspaces[@vjson.id] = this
		c = gta.parkingspacesbych[ @hash ] or gta.parkingspacesbych[ @hash ] = []
		c.push this
		0

	event: (e) ->
		if @mission?
			@mission.callback this, e

		else if @vjson.model
			car =
				id: @reservedid
				x: @props.x
				y: @props.y
				z: 64
				r: @vjson.r
				owners: @vjson.owners
				model: @vjson.model
				color: @vjson.color or false

			car = new gta.Car car
			car.volatile = true # unnecessary. todo: test w/o this flag

		0

class Routine
	@priority: 10

	priority: -> @constructor.priority

	constructor: (@mob, @params) ->
		@type = 'Untyped Routine'
		;


	step: ->
		0

class Vendor extends Routine
	@priority: 5

	constructor: (mob, params) ->
		super mob, params

		@type = 'Vendor'

		# ---

		;

	# override
	step: ->
		# vendors typically do nothing lool
		# if @mob.active isnt null
			# console.log 'can\'t be a ped if we are breaking'

		0

class Pedestrian extends Routine
	@priority: 5

	constructor: (mob, params) ->
		super mob, params

		@type = 'Pedestrian'

		# ---

		;

	# override
	step: ->
		if @mob.active isnt null
			console.log 'can\'t be a ped if we are breaking'

		0

class TakeABreak extends Routine
	@priority: 1

	constructor: (mob, params) ->
		super mob, params

		@type = 'TakeABreak'

		# ---

		@breaking = false

		@framesperchance = @params.framesperchance or 30 + Math.random() * 50
		@chance = @params.chance/100 or 50/100
		@framesforactivity = 10 # 10 = 1s because of game loop of 10hz/ 100ms

		@lasttried = gta.frame

		;

	# override
	step: ->
		return unless not @mob.active? or 'Pedestrian' is @mob.active.type

		if @breaking and gta.frame - @breaking >= @framesforactivity
			# console.log 'ok broke enough'
			@lasttried = gta.frame
			@breaking = false
		
		else if gta.frame-@lasttried >= @framesperchance

			if Math.random() < @chance
				@breaking = gta.frame
				@findBreakNode()


		0

	findBreakNode: ->

		1

class Mob extends Visual
	ids: 0
	pool: []

	quotes: [
		"Nice weather ey?",
		"This world sucks"
	]

	@factory: (mob, routine) ->
		switch routine
			when 'Vendor' then new Vendor mob, routine
			when 'Pedestrian' then new Pedestrian mob, routine
			when 'TakeABreak' then new TakeABreak mob, routine
			else
				null

	constructor: (props) ->
		super props

		props.id = Mob::ids++ if not props.id?

		if -1 isnt Mob::pool.indexOf @props.id
			console.log "Mob exists"
			return

		Mob::pool.push @props.id
		
		@type = 'Mob'

		@id = "g#{props.id}"

		props.r = Math.random() * Math.PI
		
		@anchor = gta.chunks[ props.ch ]

		@active = null
		@routines = []
		@addroutine r for r in props.routines
		@sortroutines()

		@traversed = []

		return unless @spawn @anchor # return refrains add to ch

		@embody()
		props.r = @pointatv @walk if @walk?

		@reduce()

		@rechunk()

		# : > BULLSHIT VARS FOLLOW : >

		# @state 'w', 1
		@walking = false
		@running = false

		# ccw,0 is left, 90 is bottom, -90 is top, 180 and -180 is right
		r = Math.ceil Math.random() * 8
		@bearing = -180 + r * 45

		@aim = -1
		@turn = 0
		@bored = -1
		@pause = -1
		@stray = -1

		@floored = 0

		skin = ['wh','wh','wh','gl','bl'][ Math.floor Math.random() * 5 ]
		feet = ['lo', 'sn', 'al', 'dr'][ Math.floor Math.random() * 4 ]
		legs = ['je', 'de', 'kh'][ Math.floor Math.random() * 3 ]
		body = ['po', 'sw', 'bo', 'pa', 'sh', 'co'][ Math.floor Math.random() * 6 ] 
		hair = ['br'][ Math.floor Math.random() * 1 ]

		hair = 'Bl' if skin is 'bl' 					# black men have black hair
		feet = 'dr' if legs is 'kh' and feet is 'lo'	# dress shoes when trying loafers /w khaki (bad contrast in brown shoes/pants)
		skin = 'gl' if skin is 'bl'	and body is 'po'	# become white when black /w poncho
		hair = 'ph' if body is 'po'						# poncho hood
		legs = 'je' if body is 'po' and legs is 'kh'	# jeans when trying khaki /w poncho (its too brown)
		feet = 'sn' if body is 'po' and feet is 'dr'	# sneakers when trying dress shoes /w poncho (dress shoes too nice for ponchoman)
		
		if props.zombie
			skin = 'zo'
			# @type = 'Zombie'

		if props.subtype is 'Hitman'
			skin = 'le'
			feet = 'dr'
			legs = 'de'
			body = 'sh'
			hair = 'ba'
			@state 'u', 'Compact 45'


		@state 'o', "#{skin}#{feet}#{legs}#{body}#{hair}"
		@parts = []
		@parts.push skin, feet, legs, body, hair

		@briefcase = 1 # Math.random() < .5
		@state 'b', 1 # @briefcase

		@health = 100
		@kill = false
		@dead = false

		@haste = 0.22 + Math.random() * 0.1
		@panic = false

	# override
	dtor: ->
		i = Mob::pool.indexOf @props.id
		Mob::pool.splice i, 1 if i isnt -1

		gta.chunks[@walk?.hash]?.pedsbound--

		gta.world.DestroyBody @body if @body?
		@body = null

		super()
		1

	embody: ->
		@bd = new box2d.Dynamics.b2BodyDef()
		@bd.type = box2d.Dynamics.b2Body.b2_dynamicBody
		@bd.position.Set @props.x / gta.scaling, @props.y / gta.scaling

		@circleShape = new box2d.Collision.Shapes.b2CircleShape 6 / gta.scaling

		fd = new box2d.Dynamics.b2FixtureDef
		fd.shape = @circleShape
		fd.density = 1
		if not @props.interior
			fd.filter.categoryBits = gta.masks.organic
			fd.filter.maskBits = gta.masks.solid | gta.masks.organic
		else
			fd.filter.categoryBits = gta.masks.introrganic
			fd.filter.maskBits = gta.masks.intrsolid | gta.masks.introrganic
		# @fd.friction = 0.4

		@body = gta.world.CreateBody @bd
		@body.SetAngle @props.r
		@body.SetUserData this
		@fixture = @body.CreateFixture fd

		@body.SetLinearDamping 2.3
		@body.SetAngularDamping 1.5
		true

	# override
	whole: -> super()

	# override
	#pack: ->
		#a = super()

		#return a

	addroutine: (r) ->
		@routines.push Mob.factory this, r
		1

	sortroutines: ->
		@routines.sort (a,b) -> if a.priority() < b.priority() then return -1 else 1
		1

	# override
	pose: ->
		pos = @body.GetPosition()
		@props.x = pos.x * gta.scaling
		@props.y = pos.y * gta.scaling

		@props.r = @body.GetAngle()

		@reduce()

		con = 	@before.reduced.x isnt @reduced.x or
				@before.reduced.y isnt @reduced.y or
				@before.reduced.r isnt @reduced.r or
				@before.reduced.z isnt @reduced.z

		if con
			at = @at
			travel = @update()

			if not @at.observed and @at.beyond @anchor
				# console.log 'Mob may not travel unobserved for two chs, dtoring'
				@dtor()

		true

	# override
	step: ->
		@rot() if @dead

		return if @dtord
		
		@anim() if @body?

		@anchor = @at if @at.observed

		@die() if @kill

		return if @dead

		floored = not (@floored < Date.now()-1500)
		return if floored

		@getup() if @states.fall?

		@pose()

		return if @dtord

		r.step() for r in @routines

		@move()

		#@agro()

		#@ramble()

		true

	use: -> # Mob::quotes[Math.floor Math.random() * Mob::quotes.length]
		"My clothes are #{@states.o}, and im a #{@type}"

	# override
	after: ->
		delete @states.s
		delete @states.h
		delete @states.up
		delete @states.e
		delete @states.q
		delete @states.a # alarmed
		delete @states.r # run over

		true

	rot: ->
		@dtor() if @died < Date.now() - 60000

		true

	spawn: (ch) ->
		if 'Pedestrian' not in @props.routines
			return true

		# unless we a ped, we just spawn freely regardless of overpopulation
		
		if ch.observed and ch.firststep
			# firststep ch gets mob

			walks = ch.walks?.slice 0
			return unless walks?

			walk = random walks
			links = walk.vjson.links

			options = []

			for i in links
				l = gta.walks[ i ]
				continue unless l?
				c = gta.chunks[ l.hash ]
				options.push l if not c? or c?.firststep

			return false if not options.length

			link = random options

			unless link?
				console.log 'pedspawn: a link doesnt exist. this can happen'.red
				return false

			tweens = Walk::gettweens walk, link
			tween = random tweens

			@walk = walk
			@comefrom = link

			@props.x = tween.x
			@props.y = tween.y

		else
			# refill via unobserved surrounding ch

			@walk = gta.walks[@props.to]
			@comefrom = gta.walks[@props.from]

			@props.x = @comefrom.props.x
			@props.y = @comefrom.props.y

		@traversed.push @comefrom

		gta.chunks[@walk.hash]?.pedsbound++ or @walk.pedsbound++

		true

	anim: ->
		motion = @body.GetLinearVelocity().Length()

		if @walking
			@walking = false if motion < .5
		else
			@walking = motion > .8

		if @running
			@running = false if motion < 2
		else
			@running = motion > 3

		if @running and @states.w isnt 2
			@state 'w', 2
		else if @walking and not @running and @states.w isnt 1
			@state 'w', 1
		else if not @walking and not @running and @states.w isnt 0
			@state 'w', 0

		1

	renode: (force) ->
		that = this

		x = Math.abs @props.x - @walk.props.x
		y = Math.abs @props.y - @walk.props.y
		range = Math.hypot x, y

		if force or range < 20 or @panic and range < 38
			a = @walk.vjson.links.slice 0
			# a = a.filter (e) -> gta.walks[e] not in that.traversed

			i = Math.floor Math.random() * a.length

			# todo: really untested angle-biased preferencing
			# todo: test this decently or rewrite
			# todo: possibly preprocess the angles from any given node

			ws = []
			for i in a
				w = gta.walks[ i ]
				continue unless w?

				theta = @walk.angletoid[i]

				d = 180 - Math.abs(Math.abs(theta - @bearing) - 180);

				ws.push walk: w, angle: d

			ws.sort (a,b) -> if a.angle < b.angle then return -1 else 1
			ws.sort (a,b) ->
				c = a.walk in that.traversed
				d = b.walk in that.traversed
				
				if not c and d
					return -1
				else if c is d
					return 0
				else if c and not d
					return 1


			@comefrom = @walk
			@walk = ws[0]?.walk or @comefrom

			@traversed.push @comefrom

			@traversed.shift() if @traversed.length > 30

			gta.chunks[@comefrom.hash]?.pedsbound-- or @comefrom.pedsbound--
			gta.chunks[@walk.hash]?.pedsbound++ or @walk.pedsbound++

			@stray = -1

			# console.log "new node is #{a[i]}"

		0

	move: ->
		return unless @walk?

		t = Date.now()

		a = @body.GetAngle()

		return unless @pause < t

		@renode()

		stray = @stray > t and @stray isnt -1

		if not stray
			@aim = @pointatv @walk
			@stray = t + 500 + Math.random() * 750

		if stray and @aim isnt -1

			c = Math.PI/40

			if @turn > 0
				n = a + c
				n = @aim if n > @aim and n <= @aim + c*2

			else if @turn < 0
				n = a - c
				n = @aim if n < @aim and n >= @aim - c*2

			if n > Math.PI*2
				n = n-(Math.PI*2)
			else if n < 0
				n = (Math.PI*2)-n

			@aim = -1 if n is @aim

			@body.SetAngle n

		a = @body.GetAngle()


		fifty = Math.random() > .5
		look = Math.random() * Math.PI/3
		@aimto if fifty then a+look else a-look

		@theta = a + Math.PI/2

		@limp true

		0

	aimto: (aim) -> # slowly
		a = @body.GetAngle()

		@aim = aim

		@turn = @aim - a

		# normalize
		@turn = -(((Math.PI*2)+a) - @aim) if @turn > Math.PI
		@turn = ((Math.PI*2)-a) - @aim if @turn < -Math.PI
		0

	pointatv: (v) ->
		@theta = Math.atan2 @props.y-v.props.y, @props.x-v.props.x

		r = @theta - Math.PI/2
		r += Math.PI*2 if r < 0

		@body.SetAngle r

		r

	limp: (slow) ->
		theta = @theta
		theta += Math.PI

		s = if slow then @haste else 0.8

		x = s * Math.cos theta
		y = s * Math.sin theta
		to = new box2d.Common.Math.b2Vec2 x, y

		theta = @theta

		@body.ApplyImpulse to, @body.GetWorldCenter()

		true

	hit: (from, using, damage) ->
		return false if @dead or @kill

		if from.type is 'Zombie'
			@health -= 34
			@panic = true
			@state 'h', 0

		else if from.type is 'Car'
			floored = not (@floored < Date.now()-1500)
			unless floored
				@health -= damage if damage?
				if @kill
					@state 'r', 0 # run over
				else
					@state 'h', 0 # hit
					@fall()

		else if using?.type is 'Gun'
			@panic = true
			@state 'a', Math.floor Math.random() * 4 # alarmed
			@health -= damage
			@state 'h', 1 # hit

			# if Math.random() < .5
			r = Math.floor Math.random() * 8
			new Decal decal: "b#{r}", x: @props.x, y: @props.y

		else if using?.type is 'Melee'
			@panic = true
			@health -= damage
			@state 'h', 1

			r = Math.floor Math.random() * 8
			new Decal decal: "b#{r}", x: @props.x, y: @props.y

		if @panic
			@haste = 0.75

		@checkup()
		true

	checkup: ->
		@kill = true if @health <= 0

		true

	die: ->
		delete @states.fall
		delete @states.up
		delete @states.s

		@dead = true
		@kill = false

		@died = Date.now()
		
		@state 'd', Math.floor Math.random() * 10

		gta.world.DestroyBody @body if @body?
		@body = null

		gta.drop this if Math.random() < .3

		gta.loot this if Math.random() < .6	
		
		true

	fall: ->
		delete @states.s

		@floored = Date.now()

		# gta.world.DestroyBody @body
		# filter = new box2d.Dynamics.b2FilterData
		filter = @fixture.GetFilterData()
		filter.categoryBits = gta.masks.none
		filter.maskBits = gta.masks.none
		@fixture.SetFilterData filter

		@state 'fall', 0 + Math.floor Math.random() * 3

		true

	getup: ->
		delete @states.fall

		@state 'up', 1 # get up

		filter = @fixture.GetFilterData()
		filter.categoryBits = gta.masks.organic
		filter.maskBits = gta.masks.solid | gta.masks.organic
		@fixture.SetFilterData filter
		true



gta.Car = Car
gta.Visual = Visual

gta.account = require('./account')
gta.missions = require('./missions')

gta.start()