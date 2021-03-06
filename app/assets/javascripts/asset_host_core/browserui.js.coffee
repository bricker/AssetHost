class AssetHost.BrowserUI
    DefaultOptions:
        assetBrowserEl: "#asset_browser"
        modalSelect:    true
        modalAdmin:     true
        assets: []

    constructor: (options={}) ->
        @options = _.defaults options, @DefaultOptions

        @assets = new AssetHost.Models.PaginatedAssets @options.assets

        if @options.page
            @assets.page @options.page

        if @options.query
            @assets.query @options.query

        if @options.total
            @assets.total_entries = @options.total

        @browserEl = $(@options.assetBrowserEl)
        @browser = new AssetHost.Models.AssetBrowserView collection: @assets

        @browserEl.html @browser.el
        @browserEl.after @browser.pages().el

        # add search box
        @search = new AssetHost.Models.AssetSearchView collection:@assets
        $('#search_box').html @search.render().el

        # -- Handle Routing -- #

        @router = new BrowserUI.Router
        @router.bind "route:asset", (id) => @previewAsset id
        @router.bind "route:index", => @clearDisplay()
        @router.bind "route:search", (page,query) =>
            @clearDisplay()
            @loadAssets query:query, page:page

        # -- Handle Events from UI Elements -- #

        @browser.pages().bind "page", (page) =>
            @clearDisplay()
            @loadAssets page: page
            @navToAssets()

        @search.bind "search", (query) =>
            @clearDisplay()
            @loadAssets query:query, page:1
            @navToAssets()

        @browser.bind "click", (asset) =>
            @clearDisplay()
            @_previewAsset(asset)

        Backbone.history.start pushState:true, root:@options.root_path

        $(@browserEl).delegate "button", "dragstart", (evt) ->
            if url = $(evt.currentTarget).attr 'data-asset-url'
                evt.originalEvent.dataTransfer.setData 'text/uri-list', url

        @assets.trigger 'reset'

    #----------

    navToAssets: ->
        page = @assets.page()
        query = @assets.query()

        if page && query
            @router.navigate("/p/#{page}/#{query}")
        else if page && page != 1
            @router.navigate("/p/#{page}")
        else
            @router.navigate("/")

    #----------

    # given a query string and/or page number, grab assets via the API and
    # fill in the asset browser
    loadAssets: (options = {}) ->
        qDirty = (options['query'] || @assets.query()) && options['query'] != @assets.query()
        pDirty = options['page'] && Number(options['page']) != Number(@assets.page())

        if qDirty || pDirty || options['force']
            # display loading status. browserView will clear on its own
            @browser.loading()

            # fire off AJAX API request
            @assets.query(options['query'])
            @assets.page(options['page'])
            @assets.fetch(reset: true)

            false

    #----------

    clearDisplay: ->
        # clear any asset modal
        $(".ui-dialog-titlebar-close").trigger('click')

    #----------

    previewAsset: (id) ->
        # check if we have the asset
        asset = @assets.get(id)

        if !asset
            a = new AssetHost.Models.Asset(id: id)
            a.fetch
                success:(a)=> @_previewAsset(a)

        else
            @_previewAsset(asset)

    _previewAsset: (asset) ->
        asset.modal().open
            options:
                close:  => @navToAssets(),
            select: @options.modalSelect,
            admin:  @options.modalAdmin

    #----------

    class @Router extends Backbone.Router
        routes:
            '/a/:id': "asset"
            '/p/:p/:query': "search"
            '/p/:p': "search"
            '/': "index"
            '': "index"

        asset: ->

        search: ->

        index: ->

