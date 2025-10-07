library(jsonlite)

minsetsize = 4
maxsetsize = 32

positiontable = cbind(rep(-2:3, 6), rep(-3:2, each=6))
colnames(positiontable) = c("x", "y")

positiontablex = positiontable * 50

countervalue <<- 1
counter = function() {
  z = countervalue
  countervalue <<- countervalue + 1
  return(z)
}

# Store all trials
all_trials = list()

# Set of sizes
j = 4

for (setsize in c(4, 8, 16, 32)) {

  # Target present trials
  for (i in 1:j) {
    trial = list()
    trial[[1]] = counter()
    trial[[2]] = 1  # target present
    trial[[3]] = setsize

    stimulipos = sample(c(1:18, 20:36), setsize)
    stimuli = c("target", sample(c("distractor1", "distractor2"), replace = TRUE, setsize - 1))

    for (k in 1:setsize) {
      pos = positiontablex[stimulipos[k], ]
      trial = append(trial, list(stimuli[k], pos[1], pos[2]))
    }

    for (k in seq_len(maxsetsize - setsize)) {
      trial = append(trial, list("empty", 250, 250))
    }

    trial = append(trial, list(0))
    print(paste("Trial", trial[[1]], "length:", length(trial)))
  # optional ending marker
    all_trials[[length(all_trials) + 1]] = trial
  }

  # Target absent trials
  for (i in 1:j) {
    trial = list()
    trial[[1]] = counter()
    trial[[2]] = 0  # target absent
    trial[[3]] = setsize

    stimulipos = sample(c(1:18, 20:36), setsize)
    stimuli = sample(c("distractor1", "distractor2"), replace = TRUE, setsize)

    for (k in 1:setsize) {
      pos = positiontablex[stimulipos[k], ]
      trial = append(trial, list(stimuli[k], pos[1], pos[2]))
    }

    for (k in seq_len(maxsetsize - setsize)) {
      trial = append(trial, list("empty", 250, 250))
    }

    trial = append(trial, list(0))  # optional ending marker
    print(paste("Trial", trial[[1]], "length:", length(trial)))
    all_trials[[length(all_trials) + 1]] = trial
  }
}

# Convert to JSON
json_output = toJSON(all_trials, pretty = TRUE, auto_unbox = TRUE)

# Write to file
write(json_output, file = "stimuli_output3.json")
