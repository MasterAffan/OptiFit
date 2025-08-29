
def test_result(client):
    response = client.get("/result/invalid_id")
    assert response.status_code == 404
    assert response.get_json()["status"] == "not_found"
