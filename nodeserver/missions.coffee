missions = {}

class Mission
	doublecolon = yes

	constructor: (@ses) ->

		;

	cleanup: ->
		0

	fetch: ->
		query = "SELECT * FROM `accounts` WHERE x >= #{@ux} AND y >= #{@uy} AND x < #{@uex} AND y < #{@uey}"
		
		that = this
		
		gta.db.query query, (err, rows) ->
			that.take rows
			return
		0

	take: (param) ->
		@data = 0
		true

class Hotline extends Mission
	STAGES:
		GO_TO_RENTAL: 1
		DRIVE_TO_PLACE: 2
		GO_INSIDE: 3
		FOUR: 4

	constructor: (ses) ->
		super ses

		@stage = Hotline::STAGES.GO_TO_RENTAL
		@failed  = false

		@drivehere = x: 530, y: 270

		@spawn = null
		@spawned = false

		@rental = null

		parkingspaces = gta.nearestparkingspacesbych[@ses.ply.at.hash]

		@ses.bubbles.push "<span style='color: gold; ffont-size: 12px'>Mission: 'Tis not too late to seek a newer world</span>"

		for i, p of parkingspaces

			continue unless p.v.vjson.type is 'spawn'

			ch = gta.chunks[p.v.hash]

			continue if ch? and ch.observed

			continue if p.v.mission? # already taken

			console.log "took spawn #{p.v.id}".cyan

			@spawn = p.v
			p.v.mission = this
			break

		a = this
		cb = -> a.first()
		setTimeout cb, 2000

		;

	first: ->
		if not @spawn?
			@ses.bubbles.push "<span style='color: gold'>No free parking spots to spawn your car, mission can\'t start</span>"
			return
		@ses.out.TARGET = x: @spawn.props.x, y: @spawn.props.y
		@ses.bubbles.push "<span style='color: gold'>Get to the rental</span>"
		0

	fail: ->
		@failed = true
		@cleanup()
		0

	cleanup: ->
		super()

		@ses.out.NOTARGET = 1

		if @spawn?
			@spawn.mission = null
			@spawn = null

		if @rental?
			@rental.mission = null
			@rental.owner = null
			@rental = null

		0

	callback: (v, event) ->

		return if @failed

		if v.type is 'Parking space' and event is 'peekaboo'

			return if @spawned
			
			rental =
				x: v.props.x
				y: v.props.y
				z: 64
				r: v.vjson.r
				model: 'Bug'
				color: 'blue'

			@rental = new gta.Car rental
			@rental.volatile = true
			@rental.owner = @ses.ply
			@rental.mission = this

			@spawned = true

		else if v.type is 'Car' and event is 'dtor'

			if @stage is Hotline::STAGES.GO_TO_RENTAL
				@spawned = false
				console.log 'car unspawned'

			else if @stage is Hotline::STAGES.DRIVE_TO_PLACE
				@ses.bubbles.push "<span style='color: gold'>You lost your car</span>"
				@fail()
				return

			@spawned = false

		0

	step: ->
		return if @failed

		if @stage is Hotline::STAGES.GO_TO_RENTAL and @ses.ply.car? and @ses.ply.car is @rental

			@ses.out.TARGET = x: @drivehere.x, y: @drivehere.y

			@ses.bubbles.push "<span style='color: gold'>And oh, please don't hurt the car</span>"

			@spawn.mission = null
			@spawn = null

			@stage = Hotline::STAGES.DRIVE_TO_PLACE

		else if @stage is Hotline::STAGES.DRIVE_TO_PLACE

			range =  Math.hypot @ses.ply.props.x-@drivehere.x, @ses.ply.props.y-@drivehere.y

			if range < 48
				@stage = Hotline::STAGES.GO_INSIDE
				@ses.bubbles.push "<span style='color: gold'>You've arrived</span>"

		else if @stage is Hotline::STAGES.GO_INSIDE

			@ses.out.NOTARGET = 1

			@stage = Hotline::STAGES.FOUR

			@cleanup()
			;

		0

	briefing: ->
		'Hotline miami mp? Or is it just me?'

missions.Mission = Mission
missions.Hotline = Hotline
module.exports = missions