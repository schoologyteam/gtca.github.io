root = exports ? this

armory = 
	weps: null
	path: '../play/sty/nontile/mcitems/'
	types: {} # pistols, smgs, carbines, assault rifles, dmrs, snipers, knives
	nondescript: true


$(document).ready ->

	$('body').append $ '<div class="armory">'
	$('body').append $ '<div class="descriptor">'


	$.getJSON '../sons/weps.json', (data) ->
		armory.weps = data
		types.call armory
		go.call armory
		return
	
	1

$(document).mousemove (e) ->
	return if armory.nondescript

	descriptor = $ '.descriptor'
	descriptor.css 'top', e.pageY + 10
	descriptor.css 'left', e.pageX + 10
	return

types = ->
	for k, v of @weps
		a = @types[v.type] ?= []
		a.push v

	types = $ '<div class="types">'

	for k, v of @types
		type = $ "<div data-type=\"#{k}\" class=\"type\">"
		types.append type
	
	$('.armory').append types

go = ->
	for k, v of @weps
		continue if v.unlisted

		base = $ "<div class=\"wep\">"
		base.wep = v
		base.data 'wep', v
		base.css 'background-image', "url(#{@path}#{v.sty}.png)"

		base.append $ "<div class=\"stat\">#{k} [#{v.type}]</div>"
		base.append $ "<div class=\"stat\">market value: <span class=\"marketvalue\">$#{v.value}</span></div>"
		base.append $ "<div class=\"stat\">magazine: #{v.magazine}</div>"
		base.append $ "<div class=\"stat\">damage: #{v.damage}</div>"
		base.append $ "<div class=\"stat\">accuracy: #{v.accuracy}</div>"
		base.append $ "<div class=\"stat\">recoil: #{v.recoil}</div>"
		base.append $ "<div class=\"stat\">range: #{v.range}</div>"
		base.append $ "<div class=\"stat\">firerate: #{(10/v.firerate).toFixed 2}Hz</div>"

		$("*[data-type=\"#{v.type}\"]").append base

		base.mouseenter popup
		base.mouseleave popoff
	1

popup = (e) ->
	that = $ this
	wep = that.data 'wep'

	return unless wep.description

	descriptor = $ '.descriptor'

	descriptor.css 'display', ''

	descriptor.html wep.description

	armory.nondescript = false	
	1

popoff = ->
	that = $ this
	descriptor = $ '.descriptor'

	descriptor.css 'display', 'none'

	armory.nondescript = true
	1


root.armory = armory