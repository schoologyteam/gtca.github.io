text =
	'<p>
	<key>W</key><key>A</key><key>S</key><key>D</key> to move,
	<key>SPACE</key> to use,
	<key>Z</key><key>X</key> to zoom in/out<br />
	</p>

	<p>
	<key>SHIFT</key> to walk/run, <key>E</key> to interact, RIGHT MOUSE to strafe/aim
	</p>

	<!--<p>
	<key>UP</key> to bring up your phone, <key>ENTER</key> and <key>ESC</key> for menus
	</p>-->

	<p>
	<key>F3</key> to toggle minimap
	</p>'

class gg.Tour
	instance: null

	constructor: ->
		gg.Tour::instance = this

		@link = $ '<a href="javascript:;">Controls</a><br />'
		@link.click => @build()

		@slide = -1

		$('#links').append @link

	build: ->
		gg.Notice::instance.destroy() if gg.Notice::instance?.built
		gg.Settings::instance.destroy() if gg.Settings::instance?.built

		return if @built

		@built = true

		@tour = $ '<div class="popup" id="tour">'

		@tour.append '<div class="content">' + text + ' </div>'
		

		@leave = $ '<div class="button">close</div>'
		@leave.click => @destroy()

		@options = $ '<div class="options">'
		@options.append @leave
		@tour.append @options

		$('#overlay').append @tour
		
		true

	destroy: ->
		@tour.remove()
		@built = false
		true

notice = '
	<p>There are guns around the map. This is temporary.</p>
	<p>Have a look at the <a target="_blank" href="armory">armory</a>.'

class gg.Notice
	instance: null

	constructor: ->
		gg.Notice::instance = this

		@build()
		;

	build: ->
		gg.Tour::instance.destroy() if gg.Tour::instance?.built

		return if @built

		@built = true

		@element = $ '<div class="popup" id="updates">'
		
		@element.append '<p>Notice</p>'
		@element.append notice
		
		@options = $ '<div class="options">'

		@leave = $ '<div class="next">close</div>'
		@leave.click ->
			gg.notice.destroy()
			true

		@options.append @leave
		@element.append @options

		$('#overlay').append @element
		
		true

	destroy: ->
		@element.remove()
		@built = false
		true