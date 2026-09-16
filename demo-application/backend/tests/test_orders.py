def test_create_order(client):
    response = client.post("/api/v1/orders/", json={
        "customer_name": "John Doe",
        "product_name": "Widget",
        "quantity": 2,
        "unit_price": 10.50
    })
    assert response.status_code == 201
    data = response.json()
    assert data["customer_name"] == "John Doe"
    assert data["status"] == "PLACED"
    assert float(data["total"]) == 21.0

def test_list_orders(client):
    response = client.get("/api/v1/orders/")
    assert response.status_code == 200
    data = response.json()
    assert len(data) >= 1

def test_get_order(client):
    # First create one
    response = client.post("/api/v1/orders/", json={
        "customer_name": "Alice",
        "product_name": "Gadget",
        "quantity": 1,
        "unit_price": 50.0
    })
    order_id = response.json()["id"]

    # Now get it
    response = client.get(f"/api/v1/orders/{order_id}")
    assert response.status_code == 200
    assert response.json()["id"] == order_id

def test_update_order_status(client):
    response = client.post("/api/v1/orders/", json={
        "customer_name": "Bob",
        "product_name": "Thing",
        "quantity": 1,
        "unit_price": 10.0
    })
    order_id = response.json()["id"]

    response = client.patch(f"/api/v1/orders/{order_id}/status", json={"status": "PROCESSING"})
    assert response.status_code == 200
    assert response.json()["status"] == "PROCESSING"

def test_invalid_status_transition(client):
    response = client.post("/api/v1/orders/", json={
        "customer_name": "Charlie",
        "product_name": "Stuff",
        "quantity": 1,
        "unit_price": 10.0
    })
    order_id = response.json()["id"]

    # PLACED -> DELIVERED is invalid
    response = client.patch(f"/api/v1/orders/{order_id}/status", json={"status": "DELIVERED"})
    assert response.status_code == 400

def test_delete_order(client):
    response = client.post("/api/v1/orders/", json={
        "customer_name": "Dave",
        "product_name": "ToDelete",
        "quantity": 1,
        "unit_price": 10.0
    })
    order_id = response.json()["id"]

    response = client.delete(f"/api/v1/orders/{order_id}")
    assert response.status_code == 204

    response = client.get(f"/api/v1/orders/{order_id}")
    assert response.status_code == 404
