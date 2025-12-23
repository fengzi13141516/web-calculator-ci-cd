import pytest
import sys
import os
sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), '../..')))

from app import app

@pytest.fixture
def client():
    app.config['TESTING'] = True
    with app.test_client() as client:
        yield client

def test_index(client):
    """测试首页"""
    response = client.get('/')
    assert response.status_code == 200
    data = response.get_json()
    assert 'name' in data
    assert data['name'] == 'Web Calculator'

def test_add(client):
    """测试加法"""
    response = client.get('/add/2&3')
    assert response.status_code == 200
    data = response.get_json()
    assert data['operation'] == 'add'
    assert data['result'] == 5.0

def test_multiply(client):
    """测试乘法"""
    response = client.get('/multiply/4&5')
    assert response.status_code == 200
    data = response.get_json()
    assert data['operation'] == 'multiply'
    assert data['result'] == 20.0

def test_invalid_input(client):
    """测试无效输入"""
    response = client.get('/add/abc&xyz')
    assert response.status_code == 400
    data = response.get_json()
    assert 'error' in data

def test_health(client):
    """测试健康检查"""
    response = client.get('/health')
    assert response.status_code == 200
    data = response.get_json()
    assert data['status'] == 'healthy'