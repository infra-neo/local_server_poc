# Contributing to Kolaboree NG

Thank you for your interest in contributing to Kolaboree NG! This document provides guidelines and instructions for contributing.

## Getting Started

1. **Fork the repository** on GitHub
2. **Clone your fork** locally
3. **Create a branch** for your changes
4. **Make your changes** following our guidelines
5. **Test your changes** thoroughly
6. **Submit a pull request**

## Development Setup

### Prerequisites

- Docker and Docker Compose
- Python 3.11+
- Node.js 18+
- Git

### Local Development

#### Backend Development

```bash
cd backend
python3 -m venv venv
source venv/bin/activate
pip install -r requirements.txt
uvicorn app.main:app --reload
```

#### Frontend Development

```bash
cd frontend
npm install
npm start
```

## Code Style Guidelines

### Python (Backend)

- Follow PEP 8 style guide
- Use type hints where appropriate
- Document functions with docstrings
- Keep functions focused and small
- Use meaningful variable names

Example:
```python
def connect_provider(
    self, 
    connection_id: str, 
    provider_type: str, 
    credentials: Dict[str, Any], 
    region: str = None
) -> bool:
    """
    Connect to a cloud provider based on type
    
    Args:
        connection_id: Unique identifier for the connection
        provider_type: Type of cloud provider (gcp, aws, etc.)
        credentials: Provider-specific credentials
        region: Optional region specification
        
    Returns:
        bool: True if connection successful, False otherwise
    """
    # Implementation
```

### JavaScript/React (Frontend)

- Use functional components with hooks
- Follow ES6+ standards
- Use meaningful component names
- Keep components focused and reusable
- Document complex logic with comments

Example:
```javascript
/**
 * CloudProviderCard Component
 * Displays a card for a cloud provider connection
 * 
 * @param {Object} connection - The cloud connection object
 * @param {Function} onViewNodes - Callback to view nodes
 */
const CloudProviderCard = ({ connection, onViewNodes }) => {
  // Implementation
};
```

## Adding New Cloud Providers

To add support for a new cloud provider:

1. **Update `cloud_manager.py`**:
   - Add a `connect_<provider>` method
   - Add a `list_<provider>_nodes` method
   - Add the provider to `connect_provider` and `list_nodes` methods

2. **Update frontend**:
   - Add provider to `providerOptions` in `WizardConector.js`
   - Add provider logo/emoji to `providerLogos` in `CloudProviderCard.js`
   - Add provider-specific form fields if needed

3. **Test thoroughly**:
   - Test connection with real credentials
   - Test listing resources
   - Test error handling

4. **Update documentation**:
   - Add provider to README.md
   - Document required credentials
   - Add usage examples

## Pull Request Process

1. **Update documentation** for any user-facing changes
2. **Add tests** for new functionality
3. **Ensure all tests pass**
4. **Update CHANGELOG.md** with your changes
5. **Write a clear PR description**:
   - What changes were made
   - Why the changes were needed
   - How to test the changes

## Commit Message Guidelines

Use clear, descriptive commit messages:

```
feat: Add support for AWS EC2 provider
fix: Resolve connection timeout in LXD client
docs: Update README with deployment instructions
refactor: Simplify cloud manager initialization
test: Add unit tests for GCP connector
```

Prefixes:
- `feat:` - New feature
- `fix:` - Bug fix
- `docs:` - Documentation changes
- `refactor:` - Code refactoring
- `test:` - Adding or updating tests
- `chore:` - Maintenance tasks

## Testing

All contributions should include appropriate tests:

### Backend Tests

```python
# tests/test_cloud_manager.py
def test_connect_gcp():
    manager = CloudManager()
    result = manager.connect_gcp(
        "test-id",
        {"service_account_json": mock_credentials}
    )
    assert result is True
```

### Frontend Tests

```javascript
// components/admin/CloudProviderCard.test.js
test('renders cloud provider card', () => {
  render(<CloudProviderCard connection={mockConnection} />);
  expect(screen.getByText('GCP')).toBeInTheDocument();
});
```

## Code Review Process

1. A maintainer will review your PR
2. Address any feedback or requested changes
3. Once approved, your PR will be merged

## Areas for Contribution

We especially welcome contributions in these areas:

### High Priority
- [ ] Implement remaining cloud provider connectors
- [ ] Add comprehensive error handling
- [ ] Improve security features
- [ ] Add unit and integration tests
- [ ] Improve documentation

### Features
- [ ] User permission management
- [ ] Drag-and-drop permission assignment
- [ ] Resource monitoring and metrics
- [ ] Cost tracking
- [ ] Backup and restore functionality

### Infrastructure
- [ ] Kubernetes deployment support
- [ ] CI/CD pipeline improvements
- [ ] Performance optimizations
- [ ] Monitoring and logging

## Getting Help

- **Issues**: Check existing issues or create a new one
- **Discussions**: Use GitHub Discussions for questions
- **Documentation**: Refer to README.md and other docs

## License

By contributing, you agree that your contributions will be licensed under the MIT License.

## Code of Conduct

- Be respectful and inclusive
- Provide constructive feedback
- Focus on what is best for the community
- Show empathy towards other contributors

Thank you for contributing to Kolaboree NG! 🎉
