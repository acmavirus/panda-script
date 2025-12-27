package terminal

import (
	"bufio"
	"io"
	"log"
	"net/http"
	"os/exec"
	"runtime"

	"github.com/gin-gonic/gin"
	"github.com/gorilla/websocket"
)

var upgrader = websocket.Upgrader{
	CheckOrigin: func(r *http.Request) bool {
		return true
	},
}

func HandleWebsocket(c *gin.Context) {
	conn, err := upgrader.Upgrade(c.Writer, c.Request, nil)
	if err != nil {
		log.Println("Upgrade error:", err)
		return
	}
	defer conn.Close()

	// Determine shell based on OS
	shell := "bash"
	if runtime.GOOS == "windows" {
		shell = "powershell"
	}

	cmd := exec.Command(shell)
	
	// Create pipes
	stdin, err := cmd.StdinPipe()
	if err != nil {
		log.Println("Stdin pipe error:", err)
		return
	}
	stdout, err := cmd.StdoutPipe()
	if err != nil {
		log.Println("Stdout pipe error:", err)
		return
	}
	stderr, err := cmd.StderrPipe()
	if err != nil {
		log.Println("Stderr pipe error:", err)
		return
	}

	if err := cmd.Start(); err != nil {
		log.Println("Start error:", err)
		return
	}

	// Goroutine to send stdout/stderr to websocket
	go func() {
		scanner := bufio.NewScanner(io.MultiReader(stdout, stderr))
		for scanner.Scan() {
			err := conn.WriteMessage(websocket.TextMessage, scanner.Bytes())
			if err != nil {
				log.Println("Write error:", err)
				return
			}
		}
	}()

	// Read from websocket and write to stdin
	for {
		_, msg, err := conn.ReadMessage()
		if err != nil {
			log.Println("Read error:", err)
			break
		}
		// Append newline if not present, as we are simulating typing commands
		if len(msg) > 0 {
			_, err = stdin.Write(append(msg, '\n'))
			if err != nil {
				log.Println("Stdin write error:", err)
				break
			}
		}
	}

	cmd.Process.Kill()
}
