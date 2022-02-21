class gg.Minimap
	constructor: ->
		@minimap = $ '<div id="minimap">'
		$('#overlay').append @minimap
		@build()
		@chase()

	dtor: ->
		@minimap.remove()

	build: ->
		@table = $('<table>')
		
		for y in [0..4]
			tr = $('<tr>')
			
			for x in [0..4]
				td = $('<td>')
				vis = 0
				vis = gg.map.chunks[y][x].visuals.length if gg.map.chunks[y][x]

				if x > 0 and x < 4 and y > 0 and y < 4
					td.addClass 'inner' if gg.map.chunks[y][x]
				else if vis
					td.addClass 'outer'

				if vis
					td.append gg.map.chunks[y][x].hash
					td.css 'opacity', vis/50
				#else if not @offChunks["#{x},#{y}"]
					#td.addClass 'nochunk'

				td.addClass 'center' if y is 2 and x is 2
				tr.append td

			@table.append tr

		@minimap.html @table

		true

	chase: ->
		return unless gg.ply?

		x = (gg.ply.props.x / gg.C.CHUNITS) - gg.map.n.x
		y = (gg.ply.props.y / gg.C.CHUNITS) - gg.map.n.y
		
		y -= 1
		x *= 40
		y *= 40

		x = Math.floor x
		y = Math.floor y

		@table.css 'left', "#{-x}px"
		@table.css 'top', "#{y}px"

		# this is the topleft position of chunk 0,0 on dynmap.png
		x = 464
		y = 400

		x -= 80
		# y -= 40
		
		x += gg.ply.props.x / 4
		y += gg.ply.props.y / 4

		# x /= 4
		# y /= 4

		@minimap.css 'background-position-x', "#{-x}px"
		@minimap.css 'background-position-y', "#{y}px"

		true