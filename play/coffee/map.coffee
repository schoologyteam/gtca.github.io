
# used to keep the pls constant
__Light_Manager = (T = 'PointLight') ->

	NUM = if gg.mobile then 5 else 8

	gg.bubble "Light Manager &lt;#{T}&gt; ( #{NUM} )"

	o =
		pool: []
		_pooled: 0
		lights: []
		blacks: []

		first: ->
			console.log "Light Manager <#{T}>"
			for [1..NUM]
				l = new THREE.PointLight 0x000000, 0, 0
				l.position.z = -5000
				@blacks.push l
			1

		register: (l) ->

			@pool.unshift l
			
			@process()

			0

		process: -> # also processes

			gg.scene.remove l for l in @pool
			
			_sort = (a,b) ->
				c = a.position.clone().distanceToSquared gg.camera.position.clone()
				d = b.position.clone().distanceToSquared gg.camera.position.clone()
				c-d


			_filter = (pl) ->
				v = pl._visual
				r = v.props

				interiormatch = gg.interior? and gg.interior.name is r.interior

				nointerior = not gg.interior? and not r.interior?

				visible = interiormatch or nointerior

				return visible

			pool = @pool.slice 0
			pool = pool.filter _filter
			pool = pool.concat @blacks
			pool.sort _sort

			# gg.scene.remove l for l in pool

			array = pool.slice 0, NUM

			gg.scene.add l for l in array

			@lights = array

			@_pooled = "#{@pool.length} of #{NUM} max"

			1

		checkoff: (l) ->

			@pool.splice @pool.indexOf(l), 1

			@process()

			0

	o.first()

	o

class gg.Map

	constructor: ->
	
		@mesh = new THREE.Mesh()
		
		@meshes = [] # for lb
		
		@copy = []
		@chunks = []
		@chunks[i] = [null, null, null, null, null] for i in [0..4]

		@build = false

		@actives = []
		@offChunks = []

		@load = false

		gg.lightmanager = __Light_Manager()

	getNosj: ->

		$.ajaxSetup 'async': false

		self = this

		$.getJSON "sons/nosj.json", (data) -> self.nosj = data

		true

	###
	used to initially collect all nosj.json elements into chunks
	###
	chunkify: ->

		ref = @nosj.visuals
		`CAT: //`
		for r in ref

			switch r.type
				when 'Pickup'
					console.log 'its a pu'
					`continue CAT` if not gg.ed?

				when 'Block', 'Surface', 'Light', 'Door', 'Neon'
					x = Math.floor r.x / gg.C.CHUNKSPAN
					y = Math.floor r.y / gg.C.CHUNKSPAN
				else
					x = Math.floor (r.x / 64) / gg.C.CHUNKSPAN
					y = Math.floor (r.y / 64) / gg.C.CHUNKSPAN

			xy = "#{x},#{y}"

			c = @offChunks[xy] or @offChunks[xy] = new gg.Chunk x,y

			c.addr r

			gg.idpoolforprops r if gg.DEV

		# ch.post() for i, ch of @offChunks

		true
		
	chunkCheck: ->
		# return unless gg.ply?

		gg.lightmanager.process()

		n = @n = {}
		n.x = Math.floor gg.x / gg.C.CHUNITS
		n.y = Math.floor gg.y / gg.C.CHUNITS
		
		d = {}
		d.x = gg.CURCHUNK[0] - n.x
		d.y = -(gg.CURCHUNK[1] - n.y)
		
		diff = d.x or d.y
		
		return if @load and not diff

		gg.CURCHUNK[0] = n.x
		gg.CURCHUNK[1] = n.y


		@shift n, d if diff or not @load

		@load = true

		true

	prepare: ->
		@copy[i] = @chunks[i].slice 0 for i in [0..4]
		@chunks[i] = [null, null, null, null, null] for i in [0..4]

		true

	shift: (n, d) ->
		# console.log('shift')
		
		@actives = []
		@prepare()
		
		for y in [0..4]
			for x in [0..4]			
				r = {}
				r.x = gg.C.CTABLE[y][x][0] + n.x
				r.y = gg.C.CTABLE[y][x][1] + n.y
				
				xy = "#{r.x},#{r.y}"
				
				v = gg.Map.v = x: x-d.x, y: y-d.y

				if v.x>=0&&v.y>=0&&v.x<5&&v.y<5
					# console.log "#{x},#{y} > #{v.x},#{v.y}"
					c = @chunks[y][x] = @copy[v.y][v.x] or null
					a = @copy[y][x] or null
					@actives.push c if c
					if a && (a.x > n.x+2 || a.x < n.x-2 || a.y > n.y+2 || a.y < n.y-2)
						# console.log "#{x},y falls out of bounds"
						a.disappear()
					else if ! c && (x > 0 && x < 4 && y > 0 && y < 4)
						# console.log "free spot #{x},#{y}"
						a = @chunks[y][x] = @offChunks[xy] or null
						if a
							a.show()
							@actives.push a

		@relit()

		@mesheseru() if gg.ed?

		gg.minimap.build() if gg.minimap?

		if gg.ed?
			gg.map.cyancubes()
			gg.map.plaster()

		true

	relit: ->
		gg.renderer.shadowMap.needsUpdate = true

		x = gg.CURCHUNK[0]+.5 * gg.C.CHUNITS
		y = gg.CURCHUNK[1]+.5 * gg.C.CHUNITS

		gg.moon.position.set x, y, 300
		gg.moon.target.position.set x+96, y-96, 0

		# gg.moon.shadow.camera.position.copy gg.moon.position

		1

	step: ->
		gg.ply?.steps?()

		gg.net.out.USE = 1 if gg.keys[69] is 1 # e

		gg.minimap.chase() if gg.minimap?
		
		v.step() for v in c.visuals for c in @actives

		if gg.net?
			v.step() for i, v of gg.net.visuals

			gg.net.in = {}

		for t in gg.trails
			t.step() if t?

		true

	dtor: (deep) ->
		c.disappear deep for c in @actives

		@copy = []
		@chunks[i] = [null, null, null, null, null] for i in [0..4]
		@load = false
		
		true

	mesheseru: ->
		console.log 'Meshes-seru!'

		# Ugly loop for Ed, blegh!

		if gg.ed?
			@meshes = []
			for a in @actives
				for v in a.visuals
					if v.mesh
						@meshes.push v.mesh

		1