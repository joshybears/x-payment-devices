
OBJECTS = {
    "device" : {
        "id" : "integer",
        "type" : "integer",
        "store_id" : "integer"
    },
    "transaction" : {
        "id" : "integer",
        "device_id" : "integer",
        "product_name_1" : "string",
        "product_sku" : "string",
        "product_name_2" : "string",
        "amount" : "numeric",
        "status" : "string",
        "card_number" : "string",
        "cvv" : "string",
        "created_at" : "timestamp",
        "happened_at" : "timestamp"
    },
    "store" : {
        "id" : "integer",
        "name" : "string",
        "address" : "string",
        "city" : "string",
        "country" : "string",
        "created_at" : "timestamp",
        "typology" : "string",
        "customer_id" : "integer",
    }
}