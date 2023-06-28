Info

    Tinkoff API (Websocket proxy for grpc streaming) v1.4
    https://tinkoff.github.io/investAPI/ws/ 

Need to add to environments yours token:

    TINKOFF_TOKEN=*TOKEN

Run docker:

    docker build -q --tag 'sockettest' .; docker run -it sockettest:latest 

or

    docker build -q --tag 'sockettest' .; docker run --env TINKOFF_TOKEN=*TOKEN -it sockettest:latest


Result
    Socket connected
    
    Socket data sent
    
    rps:     0     
    
    rps:   653  uid  107 / 210
    
    rps:    58  uid  126 / 210
    
    rps:    54  uid  126 / 210
    
    rps:    53  uid  127 / 210
    
    rps:    56  uid  130 / 210
    
    rps:    62  uid  131 / 210
    
    rps:    61  uid  132 / 210
    
    rps:    59  uid  134 / 210
    
    rps:    56  uid  134 / 210
    
    rps:    56  uid  135 / 210
    
    rps:    62  uid  135 / 210
    
    rps:    57  uid  135 / 210

    
