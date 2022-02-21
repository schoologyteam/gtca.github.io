zooms = [300, 800, 1200]

petals = [[+1, 0], [+2, -1], [+1, -2], [0, -1]]
makes = ['Entity', 'Block', 'Surface', 'Light', 'Decal', 'Activator', 'Parking space', 'Safe Zone', 'Walk', 'Drive', 'Door', 'Neon']
subtypes = ['scrub1', 'Table', 'Desk', 'Chair', 'Couch', 'Dumpster', 'Generator', 'ATM']

class gg.Editor
	constructor: ->
		console.log '~`~`~`~`~`~ New Editor mate'

		that = this

		@insect = null
		@face = 0
		@boot = null
		@ant = null
		@mark = null

		@links = []

		@linking = 'Walk'

		@incline = 1
		@make = 'Block'
		@mode = 'Select'

		@zoom = 0

		@petals = []
		
		blue = new THREE.MeshBasicMaterial color: 0x0000cc, opacity: .3, transparent: true
		geom = new THREE.PlaneGeometry 64, 64, 1

		i = 0
		for p in petals
			petal = new THREE.Mesh geom, blue
			petal.petal = yes
			petal.name = "petal #{i++}"
			petal.ggsolid = props: type: 'Petal'
			petal.position.set p[0] * 64, p[1] * 64, 64 + 1
			@petals.push petal

		@flower = off
		@bucket = off
		@brush = on
		@over = false

		@build()

		$.getJSON 'play/stys.json', (data) ->
			that.stys = data
			that.stys['~none~'] = 'spoof'

			that.cats()

		gg.ed = this

		# gg.map.dtor()

		;

	build: () ->
		ed = $ '<div id="ed">'
		cats = $ '<div id="cats">'
		stys = $ '<div id="stys">'


		fluke = 'href="javascript:;"'
		ed.append $("<a #{fluke}>export</a>").click -> gg.ed.export()

		ed.append ', '
		ed.append $("<a id=\"brush\" #{fluke}>brush: on</a>").click ->
			gg.ed.brush = ! gg.ed.brush
			$(this).html "brush: #{if gg.ed.brush then 'on' else 'off'}"
			return

		ed.append ', '
		ed.append $("<a #{fluke}>flower: off</a>").click ->
			gg.ed.flower = ! gg.ed.flower
			$(this).html "flower: #{if gg.ed.flower then 'on' else 'off'}"

			if ! gg.ed.flower
				for petal in gg.ed.petals
					gg.scene.remove petal
					index = gg.map.meshes.indexOf petal
					gg.map.meshes.splice index, 1 if -1 isnt index
			return

		ed.append ', '
		ed.append $("<a id=\"mode\" #{fluke}>mode: #{@mode}</a>").click ->
			if gg.ed.mode is 'Make'
				gg.ed.mode = 'Select'
			else
				gg.ed.mode = 'Make'

			$(this).html "mode: #{gg.ed.mode}"
			return

		ed.append ', '
		ed.append $("<a id=\"bucket\" #{fluke}>bucket: off</a>").click ->
			gg.ed.bucket = ! gg.ed.bucket
			$(this).html "bucket: #{if gg.ed.bucket then 'on' else 'off'}"
			return

		ed.append ', '
		ed.append $("<a id=\"bucket\" #{fluke}>zoom: #{zooms[@zoom]}</a>").click ->
			gg.ed.zoom = if gg.ed.zoom is 2 then 0 else gg.ed.zoom + 1
			$(this).html "zoom: #{zooms[gg.ed.zoom]}"
			gg.zoom = zooms[gg.ed.zoom]
			return

		ed.append ', '
		select = $ '<select id="makes">'
		select.append "<option>#{a}" for a in makes
		ed.append select.click =>
			@make = $('#makes option:selected').text()
			return

		select = $ '<select id="subtypes">'
		select.append "<option>#{a}" for a in subtypes
		ed.append select.click =>
			@subtype = $('#subtypes option:selected').text()
			return
		# ed.append ', '


		$('#links').remove()

		ed.append '<div>props of selected: <div id="props">nothng selected</div></div>'

		withselected = $ '<div class>with selected: </div>'
		withselected.append $("<a  #{fluke}>move (sticky)</a>").click =>
			if @mark?.object.ggsolid
				@sticky = @mark?.object.ggsolid
				gg.bubble "Stickying #{@mark?.object.ggsolid.type}"
			1
		withselected.append ', '

		withselected.append $("<a #{fluke}>delete</a>").click => @deletev @mark?.object.ggsolid
		withselected.append ', '
		withselected.append $("<a #{fluke}>> change vjson <</a>").click =>
			return unless @mark?

			v = @mark.object.ggsolid

			r = prompt 'Change vjson', v.props.vjson

			return unless r?

			v.vjson = JSON.parse r

			v.props.vjson = r

			return unless v.vjson?

			v.reload?()

			42
		withselected.append ', '
		withselected.append $("<a #{fluke}>incline: #{@incline}</a>").click ->
			if 1 is gg.ed.incline
				gg.ed.incline = -1
			else if -1 is gg.ed.incline
				gg.ed.incline = .5
			else if .5 is gg.ed.incline
				gg.ed.incline = -.5
			else if -.5 is gg.ed.incline 
				gg.ed.incline = 1

			$(this).html "incline: #{gg.ed.incline}th"
			42

		withselected.append ', '
		withselected.append $("<a #{fluke}>raise</a>").click =>
			v = @mark?.object.ggsolid
			v.props.z += 1
			v.pose()
		withselected.append ', '
		withselected.append $("<a #{fluke}>lower</a>").click =>
			v = @mark?.object.ggsolid
			v.props.z -= 1
			v.pose()
		withselected.append ', slope: '

		withselected.append $("<a #{fluke}>n</a>").click => @slopev @mark, 0
		withselected.append ','
		withselected.append $("<a #{fluke}>e</a>").click => @slopev @mark, 1
		withselected.append ','
		withselected.append $("<a #{fluke}>s</a>").click => @slopev @mark, 2
		withselected.append ','
		withselected.append $("<a #{fluke}>w</a>").click => @slopev @mark, 3

		withselected.append ', wedge: '
		withselected.append $("<a #{fluke}>ne</a>").click => @wedgev @mark, 0
		withselected.append ','
		withselected.append $("<a #{fluke}>se</a>").click => @wedgev @mark, 1
		withselected.append ','
		withselected.append $("<a #{fluke}>sw</a>").click => @wedgev @mark, 2
		withselected.append ','
		withselected.append $("<a #{fluke}>nw</a>").click => @wedgev @mark, 3

		withselected.append ', rotate 12th: '
		withselected.append $("<a #{fluke}>cw</a>").click =>
			v = @mark?.object.ggsolid
			v.props.r -= Math.PI/12
			v.pose()
		withselected.append ' - '
		withselected.append $("<a #{fluke}>ccw</a>").click =>
			v = @mark?.object.ggsolid
			v.props.r += Math.PI/12
			v.pose()

		# withselected.append ', '

		ed.append withselected

		ed.append cats
		$('#overlay').append ed
		cats.append stys
		cats.append 'palette: '


		ed.mouseenter => @over = true
		ed.mouseleave => @over = false
		1

	deletev: (v) ->
		@unmark()
		a = gg.map.nosj.visuals
		a.splice a.indexOf(v.props), 1

		a = gg.map.meshes
		a.splice a.indexOf(v.mesh), 1

		v.chunk.removev v

		gg.bubble "Deleted the selected #{v.type}"

		0

	slopev: (mark, d) ->
		v = mark?.object.ggsolid

		return unless v and (v.type is 'Block' or v.type is 'Surface')

		v.props.s ?= [0,0,0,0]

		v.props.s[d] += @incline

		v.slope()

		gg.bubble "Sloped your #{v.type} to #{v.props.s[d]}"
		0

	wedgev: (mark, d) ->
		v = mark?.object.ggsolid

		return unless v and v.type is 'Block'

		v.props.w ?= [no,no,no,no] # i will never forget

		v.props.w[d] = ! v.props.w[d]

		v.wedge()

		gg.bubble "Wedged your #{v.type}"

		1

	update: ->

		1

	key: ->

		shift = gg.keys[16]

		minus = 1 is gg.keys[189]
		plus = 1 is gg.keys[187]

		v = @insect?.object.ggsolid

		if (minus or plus) and v
			gg.bubble "Raising or lowering #{v.type} by .1"

			if minus
				v.props.z -= 8/64 * Math.abs @incline
			else
				v.props.z += 8/64 * Math.abs @incline

			v.pose()


		else if 1 is gg.keys[27] # esc
			@unmark() if @mark?
			@sticky = null
			@color object:ggsolid:w, w.constructor.color for w in @links
			@links = []

		else if 1 is gg.keys[82] # r

			return unless v?

			v.props.r = if 3 is v.props.r then 0 else v.props.r + 1

			gg.bubble "Rotate to #{v.props.r}"

			switch v.type
				when 'Block'
					gg.rotateplane v.geometry, 4, 1

				when 'Surface'
					gg.rotateplane v.geometry, 0, 1

		else if 1 is gg.keys[70] # f
			return unless v?

			v.props.f = ! v.props.f

			gg.bubble "Flip to #{v.props.f}"

			switch v.type
				when 'Block'
					gg.flipplane v.geometry, 4, 1

				when 'Surface'
					gg.flipplane v.geometry, 0, 1

		else if gg.keys[32] # spacebar

			# type = @linking is 'walks'

			gg.bubble "Linking all marked #{@linking} nodes (#{@links.length})..."

			for w in @links
				for other in @links
					continue if w is other

					if not !!~ w.vjson.links.indexOf other.vjson.id
						gg.bubble 'Linked'
						w.vjson.links.push other.vjson.id
					
				w.props.vjson = JSON.stringify(w.vjson)

			console.log "Unmarking all marked #{@linking}..."
			@color object:ggsolid:w, w.constructor.color for w in @links
			@links = []

		1

	cat: (a) ->
		stys = $ '#stys'
		stys.html ''

		gg.ed.sty = null

		return if '~none~' is a

		for folder, imgs of @stys[a]
			stys.append "<br/>#{folder}<br/>"

			for img in imgs
				lol = $ "<img src=\"play/sty/#{a}/#{folder}/#{img}\" />"
				lol.data 'path', "#{a}/#{folder}/#{img}"
				lol.click ->
					that = $ this
					that.addClass 'mark'
					gg.ed.sty?.removeClass 'mark'
					gg.ed.sty = that

				stys.append lol

		0

	cats: ->
		nyan = $ '#cats'

		for a of @stys
			console.log a
			cat = $ "<a href=\"javascript:;\" class=\"cat\">#{a}</a>"
			cat.data 'cat', a
			cat.click ->
				gg.ed.cat $(this).data 'cat'

			nyan.append cat
		1

	mousing: () ->
		return if @over

		insects = gg.raycaster.intersectObjects gg.map.meshes

		change = yes # no

		if insects.length
			boot = insects[ 0]
			ant = insects[1]

			shift = gg.keys[16]

			# return if @insect? and insect.object is @insect.object

			insect = if shift and ant? then ant else boot

			change = @insect?.object.ggsolid != insect?.object.ggsolid or @insect.faceIndex != insect.faceIndex

			# return unless change

			@color @insect, @insect?.object.ggsolid?.constructor.color if @insect?
			@color object:ggsolid:w, 0xc000ff if w is @insect?.object.ggsolid for w in @links # purple

			@color insect, 0x880000
			@color @mark, 0xffffff if @mark?

			@insect = insect
			@face = insect.faceIndex
		
		if change and not insect.object.petal
			center = insect.object.ggsolid

			y = 0
			y = 1 if insect.faceIndex == 8 or insect.faceIndex == 9

			switch center.type
				when 'Light', 'Walk', 'Drive', 'Parking space', 'Safe Zone', 'Decal' then return

			i = -1
			for petal in @petals
				i++
				clash = false or ! @flower
				want = x: center.props.x+petals[i][0]-1, y: center.props.y+petals[i][1]+1, z: center.props.z+y

				# `CAT: //`
				for ch in gg.map.actives
					break if clash

					for v in ch.visuals
						continue unless v.type is 'Block' or v.type is 'Surface'

						pos = x: v.props.x, y: v.props.y, z: v.props.z

						if want.x == pos.x and want.y == pos.y and want.z == pos.z
							clash = true
							gg.scene.remove petal
							index = gg.map.meshes.indexOf petal#
							gg.map.meshes.splice index, 1 if !!~ index
							break
							# `break CAT`
				
				continue if clash

				if not gg.scene.getObjectByName "petal #{i}"
					gg.scene.add petal
					gg.map.meshes.push petal

				props = petal.ggsolid.props
				props.x = want.x
				props.y = want.y
				props.z = want.z
				petal.position.set want.x*64+32, want.y*64+32, want.z*64


		1

	color: (insect, hex) ->
		v = insect.object.ggsolid

		return unless v?

		hex ?= gg.outside

		switch v.type
			when 'Surface', 'Decal', 'Activator', 'Sprite', 'Entity', 'Light', 'Walk', 'Drive', 'Parking space', 'Safe Zone'
				v.mesh.material.color.setHex hex

			when 'Block'
				i = gg.C.faces[insect.faceIndex]
				v.mesh?.material[i].color.setHex hex

		1

	click: ->
		return if @over

		petal = @insect?.object.petal
		v = @insect?.object.ggsolid

		if 1 is gg.left and @sticky?
			p = x: @insect.point.x, y: @insect.point.y, z: @insect.point.z
			@sticky.props.x = p.x
			@sticky.props.y = p.y
			@sticky.props.z = p.z
			@sticky.pose()
			@sticky = null
			gg.bubble "Repositioned your #{@sticky.type}"

		else if 1 is gg.right and v? and not petal and (v.type is 'Walk' or v.type is 'Drive')

			if @linking isnt v.type and @links.length
				gg.bubble "You\'re linking a different type. Press esc to link #{v.type} nodes instead of #{@linking} nodes."
				return

			else if @linking isnt v.type
				@linking = v.type

			@links.push v
			@color @insect, 0x880000

			gg.bubble "Selected #{@linking}: (#{@links.length}). Press esc to unselect all nodes."

		else if 1 is gg.left and gg.keys[88] and v?
			return if petal

			@deletev v

			if 'Walk' is v.type or 'Drive' is v.type

				gg.bubble "Smartly deleting a #{v.type} node"

				for i in v.vjson.links
					node = gg.walks[i] if 'Walk' is v.type
					node = gg.drives[i] if 'Drive' is v.type

					pos = node.vjson.links.indexOf v.vjson.id
					node.vjson.links.splice pos, 1
					node.props.vjson = JSON.stringify node.vjson

		else if 1 is gg.left and v? and @mode is 'Select'
			if petal
				gg.bubble 'Hint: Can\'t select blue tiles. If you want to build, change the mode.'
				return

			@unmark() if @mark?

			gg.bubble "Selected #{v.type}"
			$('#props').html JSON.stringify v.props
			@color @insect, 0xffffff
			@mark = @insect

			if 'Walk' is v.type or 'Drive' is v.type
				gg.bubble 'Hint: Use rightclick to select multiple nodes.'

		else if 1 is gg.right
			@paint()

		else if 1 is gg.left and v? and @mode is 'Make'

			n = {}

			if @mark?
				gg.bubble "Adopting props from mark"
				n = JSON.parse JSON.stringify @mark.object.ggsolid.props
			
			t = @sty?.data('path') or 'special/null/null.bmp'			
			
			n.type = @make

			p = x: @insect.point.x, y: @insect.point.y, z: @insect.point.z
			grit = x: @insect.object.ggsolid.props.x, y: @insect.object.ggsolid.props.y, z: @insect.object.ggsolid.props.z

			gritty = petal or v.type is 'Surface' or v.type is 'Block'

			n.x = p.x
			n.y = p.y
			n.z = p.z

			if 'Block' is v.type
				switch @insect.faceIndex
					when 0, 1 then grit.x += 1
					when 2, 3 then grit.x -= 1
					when 4, 5 then grit.y += 1
					when 6, 7 then grit.y -= 1
					when 8, 9 then grit.z += 1


			n.interior = gg.interior.name if gg.interior
			
			grid = false

			if not gritty and (@make is 'Block' or @make is 'Surface')
				gg.bubble 'Not a proper place to put this'
				return

			if @make is 'Block'  # or @make is 'Wall'
				n[f] ?= t for f in gg.C.faceNames
				grid = true

			else if @make is 'Surface'
				n.sty ?= t
				grid = true

			else if @make is 'Decal'
				n.decal = @subtype
				n.r = (Math.PI*2) * Math.random()

			else if 'Tree' is @make
				n.r = (Math.PI*2) * Math.random()

			else if 'Activator' is @make
				n.type = @subtype

			else if 'Pickup' is @make
				# n.state = {type: this.activator};
				n.type = this.pickup
				# n.vjson = '{"id":'+ gg.entitypool +',"type":"Vendor"}';

			else if 'Drive' is @make or 'Walk' is @make
				
				pool = ++gg.walkpool if 'Walk' is @make
				pool = ++gg.drivepool if 'Drive' is @make

				# grid = true if 'Drive' is @make

				obj =
					id: pool
					type: 'normal'
					links: []

				if @links.length < 1
					console.log "no links selected, making unlinked walk"

				else if @make is @linking
					console.log 'unlinking marks to interpolate with a new one'

					for w in @links
						obj.links.push w.vjson.id
						w.vjson.links.push obj.id
						for other in @links
							continue if w is other

							pos = w.vjson.links.indexOf other.vjson.id
							if pos isnt -1
								console.log 'Adding unlinked marked node'
								w.vjson.links.splice pos, 1
							
						w.props.vjson = JSON.stringify w.vjson

				n.vjson = JSON.stringify obj

				console.log 'Placed a node. Unmarking all marked links.'
				@color object:ggsolid:w, 0xc000ff for w in @links
				@links = []


			else if 'Parking space' is @make
				gg.parkingspacepool++
				n.vjson = '{"id":'+gg.parkingspacepool+',"type":"spawn"}'

			else if 'Safe Zone' is @make
				gg.entitypool++
				n.vjson = '{"id":'+gg.entitypool+',"faction":"Default"}'

			else if 'Entity' is @make
				gg.entitypool++
				n.vjson = '{"id":'+gg.entitypool+',"type":"Vendor"}'

			cx = 0
			cy = 0

			if !grid
				cx = Math.floor ((n.x / 64) / gg.C.CHUNKSPAN)
				cy = Math.floor ((n.y / 64) / gg.C.CHUNKSPAN)
			else
				n.x = grit.x
				n.y = grit.y
				n.z = grit.z
				cx = Math.floor( n.x / gg.C.CHUNKSPAN)
				cy = Math.floor (n.y / gg.C.CHUNKSPAN)

			cxy = cx+','+cy

			c = gg.map.offChunks[cxy] || (gg.map.offChunks[cxy] = new gg.Chunk(cx,cy))

			v = null
			
			v = c.addr n

			gg.map.nosj.visuals.push(n);
			
			if v.mesh
				gg.map.meshes.push(v.mesh);

			# if 'Light' is n.type || 'Walk' is n.type || 'Parking space'is n.type  || 'Safe Zone' is n.type || 'Entity' is n.type
			gg.map.cyancubes();
			
			console.log 'you placed a visual cg'
			console.log n
		1

	paint: ->
		return unless @brush and @insect? and @sty?

		visual = @insect.object.ggsolid
		return unless visual?

		sty = @sty.data 'path'

		switch visual.type
			when 'Block'
				i = gg.C.faces[@insect.faceIndex]
				visual.mesh.material[i].map = gg.loadSty sty
				visual.props[ gg.C.faceNames[i] ] = sty

			when 'Surface'
				visual.mesh.material.map = gg.loadSty sty
				visual.props.sty = sty
		1

	unmark: ->
		@color @mark, @mark.object.ggsolid?.constructor.color if @mark?
		@mark = null

		$('#props').html 'nothing selected'

		1

	optimize: (raws) ->

		raws ?= gg.map.nosj.visuals.slice 0

		for props in raws
			# delete v.temporal
			delete props.hide

			if props.type is 'Block'
				for f, i in gg.C.faceNames
					if props[f] is 'special/null/null.bmp'
						console.log 'deleting null surface'
						delete props[f]

			if props.s
				allzero = true

				for i in props.s
					if i
						allzero = false
						break

				delete props.s if allzero
		1

	export: ->

		raws = gg.map.nosj.visuals.slice 0

		@optimize raws
		
		str = JSON.stringify raws
		
		form = $ '<form id="poster" method="post" action="php/writenosj.php" style="display:none">'
		field = $ '<input type="hidden" name="served">'
		field.attr 'value', str
		form.append field
		
		$('body').append form
		form.submit()
		1