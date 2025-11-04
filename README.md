# Task Management System API

A RESTful API for managing tasks with role-based access control, built with Rails 8.1.

## Setup

### Prerequisites

- Ruby 3.2+
- Rails 8.1+
- PostgreSQL 12+ (required for optimal performance)
- Redis (for Sidekiq and caching)

### Installation

1. Clone the repository
2. Install dependencies:

   ```bash
   bundle install
   ```

3. Set up the database:

   ```bash
   # Create PostgreSQL database (if not already created)
   createdb task_management_system_development
   createdb task_management_system_test
   
   # Run migrations
   rails db:migrate
   rails db:seed
   ```

   **Note:** This application uses PostgreSQL instead of SQLite3 for better performance. PostgreSQL provides:
   - Superior query optimization for complex queries and joins
   - Better concurrent access handling
   - Advanced indexing capabilities (composite indexes, partial indexes)
   - Better performance with large datasets
   - Production-ready features like full-text search, JSON support, and more

4. Start Redis:

   ```bash
   redis-server
   ```

5. Start Sidekiq:

   ```bash
   bundle exec sidekiq
   ```

6. Start the Rails server:

   ```bash
   rails server
   ```

## API Endpoints

### Authentication

- `POST /api/v1/auth/login` - Login with email and password
- `POST /api/v1/auth/signup` - Create a new account
- `POST /api/v1/auth/logout` - Logout
- `POST /api/v1/auth/password/reset` - Request password reset

### Tasks

- `GET /api/v1/tasks` - List tasks (with filtering and pagination)
- `POST /api/v1/tasks` - Create a new task
- `GET /api/v1/tasks/:id` - Get task details
- `PATCH /api/v1/tasks/:id` - Update task
- `DELETE /api/v1/tasks/:id` - Delete task
- `POST /api/v1/tasks/:id/assign` - Assign task to user
- `POST /api/v1/tasks/:id/complete` - Mark task as complete
- `POST /api/v1/tasks/:id/export` - Trigger task export
- `GET /api/v1/tasks/dashboard` - Get dashboard statistics
- `GET /api/v1/tasks/overdue` - Get overdue tasks

### Users

- `GET /api/v1/users` - List users (admin/manager only)
- `GET /api/v1/users/:id` - Get user profile
- `PATCH /api/v1/users/:id` - Update user
- `DELETE /api/v1/users/:id` - Delete user (admin only)

### Comments

- `GET /api/v1/tasks/:task_id/comments` - List comments for a task
- `POST /api/v1/tasks/:task_id/comments` - Create a comment
- `DELETE /api/v1/tasks/:task_id/comments/:id` - Delete a comment

## Authentication-

All API requests (except auth endpoints) require an authentication token in the header:

```bash
Authorization: Bearer <authentication_token>
```

You can get the token after logging in via `/api/v1/auth/login`.

## Example API Calls

### Login

```bash
curl -X POST http://localhost:3000/api/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"admin@example.com","password":"password123"}'
```

### Create Task

```bash
curl -X POST http://localhost:3000/api/v1/tasks \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer <token>" \
  -d '{"title":"New Task","description":"Task description","priority":"medium"}'
```

### Get Dashboard

```bash
curl -X GET http://localhost:3000/api/v1/tasks/dashboard \
  -H "Authorization: Bearer <token>"
```

## Role Permissions

### Admin

- Full access to all tasks and users
- Can create, edit, delete any task
- Can assign tasks
- Can manage users

### Manager

- Can view all tasks
- Can create and edit tasks (except archived)
- Can assign tasks
- Cannot delete tasks
- Can view all users

### Member

- Can view own tasks and assigned tasks
- Can create tasks
- Can edit own tasks
- Cannot assign tasks
- Cannot delete tasks
- Can only view own profile

## Testing

Run the test suite:

```bash
bundle exec rspec
```

Generate coverage report:

```bash
COVERAGE=true bundle exec rspec
```

## Database Schema

### Users Table

- email (string, unique)
- encrypted_password (string)
- first_name (string)
- last_name (string)
- role (enum: admin, manager, member)
- authentication_token (string, unique)

### Tasks Table

- title (string)
- description (text)
- status (enum: pending, in_progress, completed, archived)
- priority (enum: low, medium, high, urgent)
- due_date (datetime)
- creator_id (references users)
- assignee_id (references users, optional)
- completed_at (datetime)

### Comments Table

- content (text)
- task_id (references tasks)
- user_id (references users)

## Background Jobs

The application uses Sidekiq for background job processing:

- **TaskNotificationJob**: Sends notifications when tasks are created or assigned
- **TaskReminderJob**: Sends reminders for tasks due in 24 hours (runs daily at 9 AM)
- **TaskArchivalJob**: Archives completed tasks older than 30 days (runs weekly on Sunday at 2 AM)
- **DataExportJob**: Generates CSV exports of user tasks

## Environment Variables

Create a `.env` file from `.env.example` and configure the required environment variables.

## Performance Optimizations

This application includes several performance optimizations:

### Database

- **PostgreSQL** is used instead of SQLite3 for better performance with complex queries and concurrent access
- **Composite indexes** are strategically placed on frequently queried columns:
  - `tasks(status, assignee_id)` - for policy scope queries
  - `tasks(assignee_id, status)` - for assigned tasks filtering
  - `tasks(creator_id, status)` - for created tasks filtering
  - `tasks(status, due_date)` - for overdue queries
  - `tasks(priority, status)` - for high priority queries
  - `comments(task_id, created_at)` - for ordered comments

### Caching

- **Redis caching** is implemented for the dashboard endpoint
  - Dashboard statistics are cached for 5 minutes
  - Cache is automatically invalidated on task create/update/delete
  - Cache keys are role-aware to ensure proper data isolation

### Query Optimization

- **Eager loading** is optimized using `preload` for associations not used in WHERE clauses
- **N+1 query prevention** through strategic use of `includes` and `preload`
- **Batch processing** in background jobs using `find_each` with appropriate batch sizes
- **Service objects** are wrapped in database transactions for data consistency

### For Background Jobs

- **TaskArchivalJob** uses `update_all` for batch updates instead of individual saves
- **DataExportJob** streams CSV generation to avoid loading all records in memory
- **TaskReminderJob** uses optimized queries with proper indexes and preloading

### Monitoring

- **Bullet gem** is configured to detect N+1 queries in development and test environments
- Performance tests verify query counts and response times

## Sidekiq Web UI

Access Sidekiq web interface at: `http://localhost:3000/sidekiq`
