class gg.Inventory
	constructor: ->
		@items = {}

		@it = null
		@using = null
		@object = null

		@sel = null

		@inventory = $ '<div id="inventory">'
		$('#overlay').append @inventory
		@build()

	dtor: ->
		@inventory.remove()

	patch: (items) ->
		@items = items
		@build()
		true

	build: ->
		inv = this
		@stuff = $ '<div class="in">'

		for k, v of @items
			e = $ "<div class=\"item\">"
			e.append "<span class=\"name\">#{k}</span>"

			if k is @using
				e.addClass 'it'
				inv.it = e

			e.click ->
				j = $ this
				return unless inv.it isnt j
				inv.it.removeClass 'it' if inv.it?
				j.addClass 'it'
				inv.using = j.children()[0].innerHTML
				inv.it = j
				gg.ply.hold gg.weps[ inv.using ] or null
				gg.net.out.SEL = inv.using

				wep = gg.weps[ inv.using ]
				if wep?
					$('#gun').empty()

					image = $ "<img src=\"play/sty/nontile/mcitems/#{wep.sty}.png\"></img>"

					stats = $ '<div class="stats">'

					#stat = $ "<div class=\"stat\">"
					#stat.append "<div class=\"name\">Damage:</div>"
					#stat.append "<div class=\"bar\"><div class=\"value\">#{wep.damage}</div></div>"
					#stats.append stat

					if wep.damage?
						damage = Math.floor wep.damage/100 * 100
						bar = Math.min(damage, 100).toFixed 0

						stat = $ "<div class=\"stat\">"
						stat.append "<div class=\"name\">Damage/</div>"
						stat.append "
						<div class=\"bar percent\">
							<div class=\"value\" style=\"width: #{bar}%\">#{damage}</div>
						</div>
						<div class=\"end\"></div>"

						stats.append stat
					
					if wep.accuracy?
						accuracy = Math.floor wep.accuracy * 100
						bar = Math.min(accuracy, 100).toFixed 0

						mix = $ '<div style="line-height: 0;">'
						stat = $ "<div class=\"stat\" style=\"width: 50%; display: inline-block;\">"
						stat.append "<div class=\"name\">Accuracy/</div>"
						stat.append "
						<div class=\"bar percent\">
							<div class=\"value\" style=\"width: #{bar}%\">#{accuracy}</div>
						</div>
						<div class=\"end\"></div>"
						mix.append stat
					
						recoil = Math.floor wep.recoil * 100
						bar = Math.min(recoil, 100).toFixed 0

						stat = $ "<div class=\"stat\" style=\"width: 50%; display: inline-block;\">"
						stat.append "<div class=\"name\" style=\"padding-left: 2ex;\">Recoil/</div>"
						stat.append "
						<div class=\"bar percent\">
							<div class=\"value\" style=\"width: #{bar}%\">#{recoil}</div>
						</div>
						<div class=\"end\"></div>"
						mix.append stat

						stats.append mix

					
					if wep.range?
						range = Math.floor wep.range * 100
						bar = Math.min(range, 100).toFixed 0

						stat = $ "<div class=\"stat\">"
						stat.append "<div class=\"name\">Range/</div>"
						stat.append "
						<div class=\"bar percent\">
							<div class=\"value\" style=\"width: #{bar}%\">#{range}</div>
						</div>
						<div class=\"end\"></div>"

						stats.append stat

					if wep.firerate
						firerate = (wep.firerate / 20) * 100
						bar = Math.min(firerate, 100).toFixed 0

						stat = $ "<div class=\"stat\">"
						stat.append "<div class=\"name\">Firerate/</div>"
						stat.append "
						<div class=\"bar percent\">
							<div class=\"value\" style=\"width: #{bar}%\">#{wep.firerate}</div>
						</div>
						<div class=\"end\"></div>"

						stats.append stat

					$('#gun').append image
					$('#gun').append stats
				else
					$('#gun').html ''

				true

			n = if v > 1 then v else '&nbsp'
			e.append "<span class=\"count\">#{n}</span>"
			@stuff.append e

		@inventory.html @stuff

		true