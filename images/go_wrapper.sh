#!/bin/sh

echoerr() { cat <<< "$@" 1>&2; }

# Create an array of command line arguments.
ARGS=("$@")

if [[ "${__doozer_group}" == "openshift-"* || -n "${OPENSHIFT_CI}" || "${CGO_CHECK}" == "1" || "${FORCE_CGO_ENABLED}" == "1" ]]; then
  echoerr "ART go wrapper: invoked"
  echoerr "----"
  echoerr "Incoming Environment:"
  env 1>&2
  echoerr "----"
  echoerr "Incoming command line arguments:"
  cat <<< "$@" 1>&2
  echoerr "----"
  echoerr "ART go wrapper: incoming CGO_ENABLED=${CGO_ENABLED}"
  echoerr "----"

  EXEMPT="0"
  if [[ "${FORCE_CGO_ENABLED}" != "1" ]]; then
    if [[ "$GOOS" == "darwin" ]]; then
      echoerr "ART go wrapper: Skipping forced CGO_ENABLED=1 due to GOOS=${GOOS} : " "$@"
      EXEMPT="1"
    fi

    if [[ -n "${GOARCH}" && "$(go.real env GOHOSTARCH)" != *"${GOARCH}"* ]]; then
      echoerr "ART go wrapper: Skipping forced CGO_ENABLED=1 due to cross-compile $(go.real env GOHOSTARCH) vs ${GOARCH} : " "$@"
      EXEMPT="1"
    fi

    if [[ "$NO_CGO_CHECK" == "1" ]]; then
      echoerr "ART go wrapper: Skipping forced CGO_ENABLED=1 due to NO_CGO_CHECK=${NO_CGO_CHECK}"
      EXEMPT="1"
    fi
  fi

  echoerr "ART go wrapper: EXEMPT: ${EXEMPT}"
  if [[ "${EXEMPT}" != "1" ]]; then

    if [[ "${NO_STATIC_REMOVAL}" != "1" ]]; then
      # Compilation with -extldflags "-static" is problematic with
      # CGO_ENABLED=1 because compilation tries to link against
      # static libraries which don't exist. Remove -static flag
      # when detected. This is tricky because extldflags can be simple
      # or something like -ldflags '-X $(REPO_PATH)/pkg/version.Raw=$(VERSION) -extldflags "-lm -lstdc++ -static"'
      ARGS=()  # We need to rebuild the argument list.
      for arg in "$@"; do
        # Note that extldflags is a flag embedded within the value of the
        # -ldflags argument. From our script's perspective, it will be part of a single
        # argument, but this argument might look like '-X $(REPO_PATH)/pkg/version.Raw=$(VERSION) -extldflags "-lm -lstdc++ -static"'.
        if [[ "${arg}" == *"-extldflags"* ]]; then
          # We replace -static with -lc because '-lc' implies to link against stdlib. This is a default
          # and should therefore be benign for virtually any compilation (unless -nostdlib or -nodefaultlibs
          # is specified -- and we don't account for this).
          # Why replace instead of remove? Consider the complex possible scenarios:
          # -ldflags '-extldflags "-static"'   # Removing -extldflags would mean we also need to remove ldflags.
          # -ldflags '-X $(REPO_PATH)/pkg/version.Raw=$(VERSION) -extldflags "-static"'  # Would remove extldflags but keep ldflags
          # -ldflags '-X $(REPO_PATH)/pkg/version.Raw=$(VERSION) -extldflags "-static -lm"'  # Would need to remove -static but keep extldflags
          # In any scenario, replacing "-static" with something benign should work without the need for complex logic.
          pre_arg="${arg}"
          arg=$(echo "${arg}" | sed "s/-static/-lc/g")
          if [[ "${pre_arg}" != "${arg}" ]]; then
            echoerr "ART go wrapper: Eliminated static"
          fi
        fi
        ARGS+=("${arg}")
      done
      echoerr "----"
      echoerr "ART go wrapper: Updated command line arguments:" "${ARGS[@]}"
      echoerr "----"
    else
      echoerr "ART go wrapper: Skipped static removal because NO_STATIC_REMOVAL=${NO_STATIC_REMOVAL}"
    fi

    if [[ "${NO_FORCE_CGO_ENABLED}" == "1" ]]; then
        export CGO_ENABLED="1"
        echoerr "ART go wrapper: Forced CGO_ENABLED=${CGO_ENABLED}"
    fi

    if [[ "${CGO_ENABLED}" == "0" ]]; then
      echoerr "ART go wrapper: Preventing compilation because CGO_ENABLED=${CGO_ENABLED}"
      exit 1
    fi

  fi

  echoerr "ART go wrapper: Invoking actual go binary"
fi

# The Dockerfile must ensure that "go.real" is in the current $PATH
go.real "${ARGS[@]}"
