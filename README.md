# Task Management System API

A RESTful API for managing tasks with role-based access control, built with Rails 8.1.

## Setup

### Prerequisites

- Ruby 3.2+
- Rails 8.1+
- SQLite3
- Redis (for Sidekiq)

### Installation

1. Clone the repository
2. Install dependencies:
   ```bash
   bundle install
   ```

3. Set up the database:
   ```bash
   rails db:create
   rails db:migrate
   rails db:seed
   ```

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

## Authentication

All API requests (except auth endpoints) require an authentication token in the header:

```
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

### Users
- email (string, unique)
- encrypted_password (string)
- first_name (string)
- last_name (string)
- role (enum: admin, manager, member)
- authentication_token (string, unique)

### Tasks
- title (string)
- description (text)
- status (enum: pending, in_progress, completed, archived)
- priority (enum: low, medium, high, urgent)
- due_date (datetime)
- creator_id (references users)
- assignee_id (references users, optional)
- completed_at (datetime)

### Comments
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

Create a `.env` file (see `.env.example`):

```
REDIS_URL=redis://localhost:6379/0
```

## Sidekiq Web UI

Access Sidekiq web interface at: `http://localhost:3000/sidekiq`

### Relationships:
- **User** has_many **Tasks** (as creator)
- **User** has_many **Tasks** (as assignee)
- **User** has_many **Comments**
- **Task** belongs_to **User** (creator)
- **Task** belongs_to **User** (assignee, optional)
- **Task** has_many **Comments**
- **Comment** belongs_to **Task**
- **Comment** belongs_to **User**
