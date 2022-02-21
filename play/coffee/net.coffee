times = []

class gg.Net
	constructor: ->
		@visuals = []
		
		@ws = null
		@open = false

		@frame = -1
		
		@in = {}
		@out = {}

		@last = x:0,y:0,r:0,z:0

		@connect()

	connect: ->
		net = this
		
		@ws = new WebSocket gg.config.ws
		
		@ws.onopen = ->

			net.open = true

			new gg.bubble 'Connected to server'

			net.interval = setInterval 'gg.net.loop()', 100
			net.loop()

			true
		
		@ws.onmessage = (evt) ->
			#console.log "got #{evt.data}"

			net.takein JSON.parse evt.data
			true

		@ws.onclose = ->
			new gg.bubble 'Connection was closed. Reload page to try to reconnect.', true if net.open

			net.open = false

			clearInterval @interval
			
			true

		@ws.onerror = (err) ->
				new gg.bubble ' <span class="fail">Can\'t reach server. Maybe it\'s down for maintenance.</span>'

				gg.zoom = gg.C.ZOOM.PED

			true

		true


	takein: (o) ->
		
		if Object.prototype.toString.call(o[0]) isnt '[object Array]'
			@in = o.shift()

		@fores()

		for e in o

			# loop :

			type = e[0].charAt 0
			id = parseInt e[0].substr 1

			statetype = e[1].type or null if e[1]?

			props = null

			props = 
			switch type
				when 'z'
					id: id, type: 'Zombie', states: e[1], 	x:e[2],y:e[3],r:e[4],z:e[5]
				when 'g', 'p'
					id: id, type: 'Man', 	states: e[1], 	x:e[2],y:e[3],r:e[4],z:e[5]
				when 'c'
					id: id, type: 'Car', 	states: e[1], 	x:e[2],y:e[3],r:e[4],z:e[5]
				when 'd'
					id: id, type: 'Decal', 	states: e[1], 	x:e[2],y:e[3],r:e[4],z:e[5]
				when 'u'
					id: id, type: 'Pickup', states: e[1], 	x:e[2],y:e[3],r:e[4],z:e[5]
				when 'm', 'n'
					id: id, type: statetype,states: e[1],	x:e[2],y:e[3],r:e[4],z:e[5]
				else
					null

			props.type = 'Player' if @YOURE is id and 'p' is type
				
			props.net = true # todo: so far only used to stop step.sprite :<

			# console.log e

			if props? and not v = @visuals[e[0]]
				@visuals[e[0]] = gg.visualFactory props
			else v.patch props

		# some more actions

		@afts()

		1

	collect: ->
		repose = false

		f2 = (a) -> a.toFixed 2

		out = []

		# `CAT: //`
		if gg.ply?

			v = gg.ply

			out[0] = parseFloat f2 v.props.x if f2(@last.x) isnt f2(v.props.x)
			out[1] = parseFloat f2 v.props.y if f2(@last.y) isnt f2(v.props.y)
			out[2] = parseFloat f2 v.props.r if f2(@last.r) isnt f2(v.props.r)
			out[3] = parseFloat f2 v.props.z if f2(@last.z) isnt f2(v.props.z)

			@last = x:v.props.x, y:v.props.y, z:v.props.z, r:v.props.r

		out[4] = gg.net.out if !! Object.keys(gg.net.out).length

		gg.net.out = {}

		out

	loop: () ->
		a = @collect()

		if a.length
			json = JSON.stringify a

			@ws.send json

		true

	fores: (e) ->

		if @in.removes
			for e in @in.removes
				continue if not (v = @visuals[e])?
				v.dtor()
				delete @visuals[e]

		if @in.bubbles
			for m in @in.bubbles
				new gg.bubble m

		if @in.quest
			for m in @in.bubbles
				new gg.bubble m

		if @in.inventory
			gg.inventory.patch @in.inventory

		if @in.YOURE
			@YOURE = @in.YOURE
			# gg.bubble "debug : YOURE #{@YOURE}"

		if @in.INTR?
			console.log "intr #{@in.INTR}"

			gg.ambient = 0x697676
			
			gg.zoom = gg.C.ZOOM.INTR

			gg.interior = new gg.Interior @in.INTR, @in.INTRSTYLE

			gg.map.dtor yes

			v.dtor() for i, v of @visuals

			@visuals = []

		if @in.OUTR?
			gg.ambient = gg.outside

			gg.zoom = if gg.melee then gg.C.ZOOM.MELEE else if gg.gun then gg.C.ZOOM.GUN else gg.C.ZOOM.PED

			gg.map.dtor yes

			@recolor()

			gg.interior.dtor()
			gg.interior = null

			v.dtor() for i, v of @visuals

			@visuals = []

		1

	recolor: ->
		for k,v of gg.materials
			continue if !!~ k.indexOf 'Interior'

			color = gg.ambient

			if !!~ k.indexOf 'Sloped'
				color = gg.darker null

			v.color = new THREE.Color color
		1

	afts: () ->

		if @in.TP? and gg.ply?
			gg.ply.props.x = @in.TP[0]
			gg.ply.props.y = @in.TP[1]
			gg.ply.props.z = @in.TP[2] if @in.TP[2]?
			gg.ply.embody()

			console.log 'in.TP'

		if @in.SEL?
			gg.inventory.sel = @in.SEL

		if gg.ply? and @in.h?
			console.log 'were hit'
			gg.play gg.sounds.kungfu[ 0 ], gg.ply

		if gg.ply? and @in.DEAD
			gg.ply.die()
			gg.inventory.patch {}

		###if gg.ply? and @in.OUTFIT
			gg.ply.props.states.o = @in.OUTFIT
			gg.ply.dressup()
			gg.zoom = gg.C.ZOOM.PED
			gg.bubble "debug : you wear #{@in.OUTFIT}"###

		if @in.CARDS
			for n in @in.CARDS

				card = $ "<div class=\"card\" data-id=\"#{n.id}\">"
				card.data 'id', n.id
				card.data 'name', n.name
				card.append "<img src=\"play/sty/nontile/pickups/#{n.name}.png\"></img>"

				card.click ->
					j = $ this
					j.addClass 'take'
					gg.net.out.CARD = j.data 'id'
					setTimeout ->
						j.remove()
					, 700
					return

			$('#pickups').append card

		if @in.RMCARDS
			for id in @in.RMCARDS
				console.log "removing #{id}"
				$(".card[data-id=\"#{id}\"]").remove()

		if @in.TARGET?
			gg.arrow.material.visible = true
			gg.arrow.pointat @in.TARGET

		if @in.NOTARGET?
			gg.arrow.material.visible = false

		if @in.YOURE
			gg.onspawn()

		if @in.LINE and gg.ply?
			new gg.Trail x: gg.ply.props.x, y: gg.ply.props.y, to: @in.LINE

		###if @in.OUTLAW?
			bandit = gg.loadSty "nontile/mobs/poncho.png"
			gg.ply.sprite.skin = bandit
			gg.ply.material.map = bandit
			gg.ply.shadowMaterial.map = bandit###

		1