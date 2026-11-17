import json
import threading
import unittest
from urllib.error import HTTPError
from urllib.request import urlopen
from http.server import ThreadingHTTPServer

from app import HealthHandler


class HealthEndpointTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.server = ThreadingHTTPServer(("127.0.0.1", 0), HealthHandler)
        cls.thread = threading.Thread(target=cls.server.serve_forever, daemon=True)
        cls.thread.start()
        cls.base_url = "http://127.0.0.1:{}".format(cls.server.server_port)

    @classmethod
    def tearDownClass(cls):
        cls.server.shutdown()
        cls.thread.join()
        cls.server.server_close()

    def test_health_returns_ok_json(self):
        with urlopen(self.base_url + "/health") as response:
            self.assertEqual(response.status, 200)
            self.assertEqual(json.loads(response.read()), {"status": "ok"})

    def test_unknown_path_returns_not_found(self):
        with self.assertRaises(HTTPError) as error:
            urlopen(self.base_url + "/missing")
        self.assertEqual(error.exception.code, 404)


if __name__ == "__main__":
    unittest.main()
