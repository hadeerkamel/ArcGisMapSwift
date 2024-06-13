- AppDelegate -

    import ArcGIS

in the didFinishLaunchingWithOptions function add your api key
  
    ArcGISEnvironment.apiKey = APIKey("Your_api_key")
    
---------------------------------------------------------------

- Search screen -
  
  let vc = ArcGisMapSearchViewController(initialLatitude: nil, initialLongitude: nil){ searchResult in
      print(searchResult) // search result is an object of latitude, longitude, address string
  }
  present(vc, animated: true)
