package task

import (
	"fmt"
	"sync"
	"time"

	"github.com/acmavirus/panda-script/v3/internal/system"
)

type TaskStatus string

const (
	Pending   TaskStatus = "pending"
	Running   TaskStatus = "running"
	Completed TaskStatus = "completed"
	Failed    TaskStatus = "failed"
)

type Task struct {
	ID        string     `json:"id"`
	Command   string     `json:"command"`
	Status    TaskStatus `json:"status"`
	Output    string     `json:"output"`
	Progress  int        `json:"progress"`
	CreatedAt time.Time  `json:"created_at"`
}

var (
	tasks = make(map[string]*Task)
	mu    sync.RWMutex
)

func CreateTask(id string, command string) *Task {
	mu.Lock()
	defer mu.Unlock()
	t := &Task{
		ID:        id,
		Command:   command,
		Status:    Pending,
		CreatedAt: time.Now(),
	}
	tasks[id] = t
	return t
}

func GetTask(id string) (*Task, bool) {
	mu.RLock()
	defer mu.RUnlock()
	t, ok := tasks[id]
	return t, ok
}

func RunTask(id string) {
	t, ok := GetTask(id)
	if !ok {
		return
	}

	mu.Lock()
	t.Status = Running
	t.Progress = 10
	mu.Unlock()

	// Simulating command execution
	output, err := system.Execute(t.Command)

	mu.Lock()
	t.Output = output
	if err != nil {
		t.Status = Failed
		t.Output += fmt.Sprintf("\nError: %v", err)
	} else {
		t.Status = Completed
		t.Progress = 100
	}
	mu.Unlock()
}
