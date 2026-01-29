#!/bin/bash

# CPU Scheduler Implementation in Bash
# Supports FCFS, SJF, Priority, and Round Robin scheduling algorithms
# Author: CPU Scheduler Project
# Version: 1.0.0

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Global variables
declare -a processes
declare -a arrival_times
declare -a burst_times
declare -a priorities
declare -a completion_times
declare -a waiting_times
declare -a turnaround_times
process_count=0
time_quantum=2

# Function to print colored output
print_color() {
    local color=$1
    local message=$2
    echo -e "${color}${message}${NC}"
}

# Function to display header
display_header() {
    clear
    print_color $BLUE "=========================================="
    print_color $BLUE "     CPU SCHEDULER SIMULATION"
    print_color $BLUE "=========================================="
    echo
}

# Function to display menu
display_menu() {
    print_color $YELLOW "Select Scheduling Algorithm:"
    echo "1. First Come First Serve (FCFS)"
    echo "2. Shortest Job First (SJF)"
    echo "3. Priority Scheduling"
    echo "4. Round Robin"
    echo "5. Exit"
    echo
}

# Function to input process details
input_processes() {
    local algo=$1
    clear
    print_color $GREEN "Enter Process Details"
    print_color $GREEN "====================="
    echo
    
    read -p "Enter number of processes: " process_count
    
    if [[ $process_count -le 0 ]]; then
        print_color $RED "Invalid number of processes!"
        return 1
    fi
    
    for ((i=0; i<process_count; i++)); do
        echo
        print_color $YELLOW "Process $((i+1))"
        read -p "Enter arrival time: " arrival_times[$i]
        read -p "Enter burst time: " burst_times[$i]
        
        if [[ $algo -eq 3 ]]; then
            read -p "Enter priority (lower number = higher priority): " priorities[$i]
        else
            priorities[$i]=0
        fi
        
        processes[$i]="P$((i+1))"
    done
}

# Function to calculate FCFS scheduling
fcfs_scheduling() {
    local current_time=0
    local total_waiting=0
    local total_turnaround=0
    
    # Sort processes by arrival time
    for ((i=0; i<process_count-1; i++)); do
        for ((j=i+1; j<process_count; j++)); do
            if [[ ${arrival_times[$i]} -gt ${arrival_times[$j]} ]]; then
                # Swap arrival times
                local temp=${arrival_times[$i]}
                arrival_times[$i]=${arrival_times[$j]}
                arrival_times[$j]=$temp
                
                # Swap burst times
                temp=${burst_times[$i]}
                burst_times[$i]=${burst_times[$j]}
                burst_times[$j]=$temp
                
                # Swap process names
                temp=${processes[$i]}
                processes[$i]=${processes[$j]}
                processes[$j]=$temp
            fi
        done
    done
    
    # Calculate completion, waiting, and turnaround times
    for ((i=0; i<process_count; i++)); do
        if [[ $current_time -lt ${arrival_times[$i]} ]]; then
            current_time=${arrival_times[$i]}
        fi
        
        completion_times[$i]=$((current_time + ${burst_times[$i]}))
        turnaround_times[$i]=$((completion_times[$i] - arrival_times[$i]))
        waiting_times[$i]=$((turnaround_times[$i] - burst_times[$i]))
        
        current_time=${completion_times[$i]}
        total_waiting=$((total_waiting + waiting_times[$i]))
        total_turnaround=$((total_turnaround + turnaround_times[$i]))
    done
    
    avg_waiting=$(echo "scale=2; $total_waiting / $process_count" | bc)
    avg_turnaround=$(echo "scale=2; $total_turnaround / $process_count" | bc)
}

# Function to calculate SJF scheduling
sjf_scheduling() {
    local current_time=0
    local total_waiting=0
    local total_turnaround=0
    declare -a completed
    declare -a visited
    
    for ((i=0; i<process_count; i++)); do
        completed[$i]=0
        visited[$i]=0
    done
    
    for ((i=0; i<process_count; i++)); do
        local min_burst=99999
        local selected=-1
        
        # Find process with minimum burst time among arrived processes
        for ((j=0; j<process_count; j++)); do
            if [[ ${arrival_times[$j]} -le $current_time && ${completed[$j]} -eq 0 ]]; then
                if [[ ${burst_times[$j]} -lt $min_burst ]]; then
                    min_burst=${burst_times[$j]}
                    selected=$j
                fi
            fi
        done
        
        # If no process has arrived, find the next arriving process
        if [[ $selected -eq -1 ]]; then
            local min_arrival=99999
            for ((j=0; j<process_count; j++)); do
                if [[ ${completed[$j]} -eq 0 && ${arrival_times[$j]} -lt $min_arrival ]]; then
                    min_arrival=${arrival_times[$j]}
                    selected=$j
                fi
            done
            current_time=${arrival_times[$selected]}
        fi
        
        # Calculate times for selected process
        completion_times[$selected]=$((current_time + ${burst_times[$selected]}))
        turnaround_times[$selected]=$((completion_times[$selected] - arrival_times[$selected]))
        waiting_times[$selected]=$((turnaround_times[$selected] - burst_times[$selected]))
        
        current_time=${completion_times[$selected]}
        completed[$selected]=1
        total_waiting=$((total_waiting + waiting_times[$selected]))
        total_turnaround=$((total_turnaround + turnaround_times[$selected]))
    done
    
    avg_waiting=$(echo "scale=2; $total_waiting / $process_count" | bc)
    avg_turnaround=$(echo "scale=2; $total_turnaround / $process_count" | bc)
}

# Function to calculate Priority scheduling
priority_scheduling() {
    local current_time=0
    local total_waiting=0
    local total_turnaround=0
    declare -a completed
    
    for ((i=0; i<process_count; i++)); do
        completed[$i]=0
    done
    
    for ((i=0; i<process_count; i++)); do
        local highest_priority=99999
        local selected=-1
        
        # Find process with highest priority (lowest priority number)
        for ((j=0; j<process_count; j++)); do
            if [[ ${arrival_times[$j]} -le $current_time && ${completed[$j]} -eq 0 ]]; then
                if [[ ${priorities[$j]} -lt $highest_priority ]]; then
                    highest_priority=${priorities[$j]}
                    selected=$j
                fi
            fi
        done
        
        # If no process has arrived, find the next arriving process
        if [[ $selected -eq -1 ]]; then
            local min_arrival=99999
            for ((j=0; j<process_count; j++)); do
                if [[ ${completed[$j]} -eq 0 && ${arrival_times[$j]} -lt $min_arrival ]]; then
                    min_arrival=${arrival_times[$j]}
                    selected=$j
                fi
            done
            current_time=${arrival_times[$selected]}
        fi
        
        # Calculate times for selected process
        completion_times[$selected]=$((current_time + ${burst_times[$selected]}))
        turnaround_times[$selected]=$((completion_times[$selected] - arrival_times[$selected]))
        waiting_times[$selected]=$((turnaround_times[$selected] - burst_times[$selected]))
        
        current_time=${completion_times[$selected]}
        completed[$selected]=1
        total_waiting=$((total_waiting + waiting_times[$selected]))
        total_turnaround=$((total_turnaround + turnaround_times[$selected]))
    done
    
    avg_waiting=$(echo "scale=2; $total_waiting / $process_count" | bc)
    avg_turnaround=$(echo "scale=2; $total_turnaround / $process_count" | bc)
}

# Function to calculate Round Robin scheduling
round_robin_scheduling() {
    read -p "Enter time quantum: " time_quantum
    
    local current_time=0
    local total_waiting=0
    local total_turnaround=0
    declare -a remaining_burst
    declare -a completed
    declare -a start_time
    
    for ((i=0; i<process_count; i++)); do
        remaining_burst[$i]=${burst_times[$i]}
        completed[$i]=0
        start_time[$i]=-1
    done
    
    local completed_count=0
    
    while [[ $completed_count -lt $process_count ]]; do
        local executed=0
        
        for ((i=0; i<process_count; i++)); do
            if [[ ${arrival_times[$i]} -le $current_time && ${completed[$i]} -eq 0 ]]; then
                if [[ ${start_time[$i]} -eq -1 ]]; then
                    start_time[$i]=$current_time
                fi
                
                if [[ ${remaining_burst[$i]} -le $time_quantum ]]; then
                    current_time=$((current_time + remaining_burst[$i]))
                    completion_times[$i]=$current_time
                    turnaround_times[$i]=$((completion_times[$i] - arrival_times[$i]))
                    waiting_times[$i]=$((turnaround_times[$i] - burst_times[$i]))
                    remaining_burst[$i]=0
                    completed[$i]=1
                    completed_count=$((completed_count + 1))
                else
                    current_time=$((current_time + time_quantum))
                    remaining_burst[$i]=$((remaining_burst[$i] - time_quantum))
                fi
                executed=1
            fi
        done
        
        if [[ $executed -eq 0 ]]; then
            # Find next arriving process
            local min_arrival=99999
            for ((i=0; i<process_count; i++)); do
                if [[ ${completed[$i]} -eq 0 && ${arrival_times[$i]} -lt $min_arrival && ${arrival_times[$i]} -gt $current_time ]]; then
                    min_arrival=${arrival_times[$i]}
                fi
            done
            if [[ $min_arrival -ne 99999 ]]; then
                current_time=$min_arrival
            else
                break
            fi
        fi
    done
    
    for ((i=0; i<process_count; i++)); do
        total_waiting=$((total_waiting + waiting_times[$i]))
        total_turnaround=$((total_turnaround + turnaround_times[$i]))
    done
    
    avg_waiting=$(echo "scale=2; $total_waiting / $process_count" | bc)
    avg_turnaround=$(echo "scale=2; $total_turnaround / $process_count" | bc)
}

# Function to display results
display_results() {
    local algo_name=$1
    
    clear
    print_color $GREEN "$algo_name Scheduling Results"
    print_color $GREEN "============================="
    echo
    
    printf "%-10s %-12s %-12s %-12s %-12s %-12s\n" "Process" "Arrival" "Burst" "Completion" "Turnaround" "Waiting"
    printf "%-10s %-12s %-12s %-12s %-12s %-12s\n" "--------" "-------" "-----" "-----------" "----------" "-------"
    
    for ((i=0; i<process_count; i++)); do
        printf "%-10s %-12s %-12s %-12s %-12s %-12s\n" \
            "${processes[$i]}" \
            "${arrival_times[$i]}" \
            "${burst_times[$i]}" \
            "${completion_times[$i]}" \
            "${turnaround_times[$i]}" \
            "${waiting_times[$i]}"
    done
    
    echo
    print_color $YELLOW "Average Waiting Time: $avg_waiting"
    print_color $YELLOW "Average Turnaround Time: $avg_turnaround"
    echo
}

# Function to generate Gantt chart
generate_gantt_chart() {
    echo
    print_color $BLUE "Gantt Chart"
    print_color $BLUE "==========="
    echo
    
    local chart=""
    local timeline=""
    local current_time=0
    
    for ((i=0; i<process_count; i++)); do
        if [[ $current_time -lt ${arrival_times[$i]} ]]; then
            chart="${chart}IDLE|"
            timeline="${timeline}${current_time}->${arrival_times[$i]} "
            current_time=${arrival_times[$i]}
        fi
        
        chart="${chart}${processes[$i]}|"
        timeline="${timeline}${current_time}->${completion_times[$i]} "
        current_time=${completion_times[$i]}
    done
    
    echo "$chart"
    echo "$timeline"
    echo
}

# Main program
main() {
    while true; do
        display_header
        display_menu
        
        read -p "Enter your choice (1-5): " choice
        
        case $choice in
            1)
                input_processes 1
                fcfs_scheduling
                display_results "First Come First Serve (FCFS)"
                generate_gantt_chart
                ;;
            2)
                input_processes 2
                sjf_scheduling
                display_results "Shortest Job First (SJF)"
                generate_gantt_chart
                ;;
            3)
                input_processes 3
                priority_scheduling
                display_results "Priority"
                generate_gantt_chart
                ;;
            4)
                input_processes 4
                round_robin_scheduling
                display_results "Round Robin"
                generate_gantt_chart
                ;;
            5)
                print_color $GREEN "Thank you for using CPU Scheduler!"
                exit 0
                ;;
            *)
                print_color $RED "Invalid choice! Please try again."
                ;;
        esac
        
        echo
        read -p "Press Enter to continue..."
    done
}

# Check if bc calculator is available
if ! command -v bc &> /dev/null; then
    print_color $RED "Error: 'bc' calculator is required but not installed."
    print_color $RED "Please install bc to run this program."
    exit 1
fi

# Start the program
main
