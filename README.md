Info

    Tinkoff API (Websocket proxy for grpc streaming) v1.4
    https://tinkoff.github.io/investAPI/ws/ 

Need to add to environments yours token:

    TINKOFF_TOKEN=*TOKEN

Run docker:

    docker build -q --tag 'sockettest' .; docker run -it sockettest:latest 

or

    docker build -q --tag 'sockettest' .; docker run --env TINKOFF_TOKEN=*TOKEN -it sockettest:latest