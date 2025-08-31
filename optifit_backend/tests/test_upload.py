import io

def test_uploading_video(client, tmp_path, monkeypatch):
    def fake_process_squat_video(input_path, output_path):
        with open(input_path, "wb") as f:
            f.write(b"Fake video data")
        with open(output_path, "wb") as f:
            f.write(b"Fake processed video data")

    monkeypatch.setattr("app.process_squat_video", fake_process_squat_video)

    video_file = tmp_path / "test_video.mp4"
    with open(video_file, "wb") as f:
        f.write(b"Test video data")

    with open(video_file, "rb") as f:
        response = client.post(
            "/upload",
            data={"video": (io.BytesIO(f.read()), "test_video.mp4")}
        )

    assert response.status_code == 200
    json_data = response.get_json()
    assert json_data["status"] == "processing"
    assert "job_id" in json_data
    assert "video_url" in json_data
