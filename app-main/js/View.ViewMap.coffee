App.View.ViewMap = Backbone.View.extend
  setView: (view) ->
    @view = view
    @listenTo Application, 'change:views:*:filters', @render
  setPage: (page) ->
    #TODO: Need a better way to figure out what page it's on
    @page = if String(page).length > 6 then page else '45.908|-78.525|3'
  render: ->
    pagePieces = @page.split '|'
    @view.run 0, (result) => # Find a way to get *all* results
      if !@map
        @$el.empty().append App.Template.ViewMap()
        @map = L.mapbox.map('map', 'examples.map-vyofok3q')
        @map.setView [pagePieces[0], pagePieces[1]], pagePieces[2]

        @map.markerLayer.on 'layeradd', (e) ->
          e.layer.bindPopup '<div id="data-' + e.layer.feature.properties.data.id + '">' +
            (App.Template.Data { data: e.layer.feature.properties.data, columns: Application._('categories:default:columns') }) +
            '</div>',
            closeButton: false
            minWidth: 320

      geojson = []

      locationColumn = Application._('categories:default:columns').findOne((column) -> column.get('type') == 'location') # in the future, be able to choose which one
      locationId = locationColumn.get('id')

      for data in result.data
        if data[locationId]?.longitude && data[locationId]?.latitude
          geojson.push
            type: 'Feature'
            geometry:
              type: "Point"
              coordinates: [data[locationId].longitude, data[locationId].latitude]
            properties: { data: new App.Model.Data data }

      @map.markerLayer.setGeoJSON geojson
      @map.on 'moveend', =>
        App.route.navigateView { page: (@map.getCenter().lat + '|' + @map.getCenter().lng + '|' + @map.getZoom()) }, false
