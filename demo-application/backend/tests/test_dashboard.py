def test_get_dashboard(client):
    response = client.get("/api/v1/dashboard/")
    assert response.status_code == 200
    data = response.json()
    assert "total" in data
    assert "by_status" in data
    assert "recent_orders" in data
