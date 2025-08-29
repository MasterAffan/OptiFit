
def test_processed(client):
    response = client.get("/processed/nonexistent.mp4")
    assert response.status_code == 404
