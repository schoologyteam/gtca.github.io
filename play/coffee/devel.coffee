## shittest file in the observable galaxy

gg.Map.prototype.plaster = ->
	no#pe

activators = [
	'Table'
	'Desk'
	'Chair'
	'Couch'
	'Lab Freezer'
	'Vacuum Oven'
	'Incubator'
	'Generator'
	'Worklight'
	'Terminal'
	'Teleporter'
	'ATM'
	'Vending Machine'
	'Dumpster'
]

gg.idpoolforprops = (r) ->
	if !!~ activators.indexOf r.props
		gg.Activator::idpool = Math.min gg.Activator::idpool, props.id

	else if r.type is 'Walk'
		vjson = JSON.parse r.vjson or null
		gg.walkpool = Math.max vjson.id or 0, gg.walkpool if vjson?
		gg.walks[vjson.id] = gg.visualFactory r if vjson.id?

	else if r.type is 'Parking space'
		vjson = JSON.parse r.vjson or null
		gg.parkingspacepool = Math.max vjson.id or 0, gg.parkingspacepool if vjson?

	else if r.type is 'Entity'
		vjson = JSON.parse r.vjson or null
		gg.entitypool = Math.max vjson.id or 0, gg.entitypool if vjson?

	0

gg.Map.prototype.cyancubes = ->
	affect = 0
	
	for a in @actives
		for v in a.visuals
			if v.cube # func exists
				affect++ if v.cube()

	# console.log "visualized #{affect} ents into cyan cubes"

	yes