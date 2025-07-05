#######################################
### Makefile structure
# Jump-table for sections
#######################################

# LBL_Info

# LBL_Makeflags
# LBL_ExecFlags

# LBL_EnvironmentVariables
# LBL_ProjectDirectories
# LBL_FileExtensions

# LBL_BinaryFiles
# LBL_SourceFiles
# LBL_ObjectFiles
# LBL_DependencyFiles
# LBL_OtherDirectories_ProjectSpecific

# LBL_Libraries
# LBL_LibraryDirectories
# LBL_LibraryDirectories_ProjectSpecific
# LBL_LibraryFlags

# LBL_IncludeDirectories
# LBL_IncludeDirectories_ProjectSpecific
# LBL_IncludeFlags

# LBL_Toolchain
# LBL_CompileFlags
# LBL_LinkFlags

# LBL_Rules
# LBL_BuildRules


#######################################
### Information
# LBL_Info
#######################################

# Makefile to build arbitrary projects that adhere to the following requirements:
# - All source files are in ./src or its subfolders
# - All header files are in ./include or ./src or their subfolders
# Host OS: linux or termux
# Target platforms: unix (default), web (with emscripten) or windows (with mingw32)


#######################################
### Makeflags
# LBL_Makeflags
#######################################

# VERSION					?= $(shell date --iso=seconds)
TESTMODE				:= false
NOGUI					:= false

### Automatically added flags to make command
MAKEFLAGS 				:= --no-print-directory #-j

#######################################
### Execution flags
# LBL_ExecFlags
#######################################

EXEC_ARGS				:= 
ifeq ($(TESTMODE),true)
    EXEC_ARGS 				:= --success
endif

#######################################
### Environment variables
# LBL_EnvironmentVariables
#######################################

### Default host OS
OS 						?= linux

ifdef TERMUX_VERSION
    OS 					:= termux
endif

### Default build mode (debug/release)
BUILD 					?= debug

### Default target platform (unix/web/windows)
PLATFORM 				?= unix


# LBL_ProjectDirectories
### Here the (latest) binary file will be output
BIN_DIR_ROOT 			:= ./bin

### Here go all source files (with the $(SRC_EXT) extension) and project specific header files
SRC_DIR 				:= ./src

### Here go all (project-)independent header files
INC_DIR 				:= ./include

### Here go all external files
LIB_DIR 				:= ./lib

### Here the object files will be outputted
BUILD_DIR_ROOT 			:= ./build

### Define folder for resource files
ASSETS_DIR	 			:= ./assets

### Define folder for test files
TEST_DIR	 			:= ./test


# LBL_FileExtensions
### Set the targets file extension
BIN_EXT 				:=
ifeq ($(PLATFORM),windows)
    BIN_EXT 				:= .exe
endif
ifeq ($(PLATFORM),web)
    BIN_EXT					:= .html
endif

### Set the used file extension for source files, usually either .c or .cpp
SRC_EXT 				:= .cpp

### Set the used file extension for object files, usually .o
OBJ_EXT					:= .o


### Set the used file extension for dependency files, usually .d (header/source connection)
DEP_EXT 				:= .d
ifeq ($(PLATFORM),windows)
    DEP_EXT 			:= .dep
endif



# LBL_BinaryFiles
### Name that the created binary should have
BIN 					:= main
ifeq ($(TESTMODE),true)
    BIN						:= test
endif

### Here is the output directory for the binaries
BIN_DIR 				= $(BIN_DIR_ROOT)/$(PLATFORM)/$(BUILD)


# LBL_SourceFiles
### Get subdirs in ./src
SRC_DIRS 				:= $(shell find . -wholename "*$(SRC_DIR)*" -type d)

TEST_DIRS 				:= $(shell find . -wholename "*$(TEST_DIR)*" -type d)


### List all source files found in source file directory w/ path from ./;
SRCS 					:= $(shell find $(SRC_DIR) -wholename "*$(SRC_EXT)" -type f)

ifeq ($(TESTMODE),true)
    SRCS 					+= $(shell find $(TEST_DIR) -wholename "*$(SRC_EXT)" -type f)
endif

### List all source files found in source file directory w/o path;
SRC_FILES 				= $(notdir $(SRCS))

### Strip file extensions to get a list of sourcefile labels
### (patsubst pattern,replacement,target)
SRC_NAMES 				= $(patsubst %$(SRC_EXT),%,$(SRC_FILES))
### Strip main or test
ifeq ($(TESTMODE),true)
    TEMP_NAMES			:= $(filter-out main,$(SRC_NAMES))
else
    TEMP_NAMES			:= $(filter-out test,$(SRC_NAMES))
endif
SRC_NAMES				= $(TEMP_NAMES)

# LBL_ObjectFiles
BUILD_DIR 				= $(BUILD_DIR_ROOT)/$(PLATFORM)/$(BUILD)

### Make list of object files need for linker command by changing ending of all source files to .o;
### IMPORTANT for linker dependency, so they are found as compile rule
OBJS 					= $(patsubst %,$(BUILD_DIR)/%$(OBJ_EXT),$(SRC_NAMES))


# LBL_DependencyFiles
### Make list of dependency files
DEPS 					= $(patsubst $(BUILD_DIR)/%$(OBJ_EXT),$(BUILD_DIR)/%$(DEP_EXT),$(OBJS))


# LBL_OtherDirectories
### Define /usr directory
ifeq ($(OS),termux)
    USR					:= $(PREFIX)
else
    USR 				:= /usr
endif
ifeq ($(PLATFORM),windows)
    USR					:= /usr/x86_64-w64-mingw32
endif

# LBL_OtherDirectories_ProjectSpecific
RAYLIB_SRC_DIR 			= $(USR)/local/lib/raylib/src


#######################################
### Libraries
# LBL_Libraries
#######################################

### Label used libraries so the respective -l flags (eg. -lraylib)
LIBRARIES 				:= raylib glfw
ifeq ($(PLATFORM),windows)
    LIBRARIES 			+= opengl32 gdi32 winmm
endif
ifeq ($(OS),termux)
    ifeq ($(PLATFORM),unix)
		LIBRARIES 			+= log
    endif
endif


# LBL_LibraryDirectories
### Here go library files
LIB_DIRS 				= $(shell find . -wholename "*$(LIB_DIR)*" -type d)

### Set the locations of system libraries
ifeq ($(PLATFORM),web)
else
    LIB_DIRS 			+= $(USR)/lib

    ifeq ($(OS),linux)
        LIB_DIRS 		+= $(USR)/local/lib
    endif
endif



# LBL_LibraryDirectories_ProjectSpecific
ifeq ($(PLATFORM),windows)
    LIB_DIRS 			+= $(RAYLIB_SRC_DIR)
else
    ifeq ($(BUILD),debug)
        ifeq ($(PLATFORM),web)
            LIB_DIRS 	+= $(RAYLIB_SRC_DIR)/lib/web/debug
        else
            LIB_DIRS 	+= $(RAYLIB_SRC_DIR)/lib/desktop/debug
        endif
    else
        ifeq ($(PLATFORM),web)
            LIB_DIRS 	+= $(RAYLIB_SRC_DIR)/lib/web/release
        else
            LIB_DIRS 	+= $(RAYLIB_SRC_DIR)/lib/desktop/release
        endif
    endif
endif


# LBL_LibraryFlags
### Make library flags by prefixing every provided path with -L; this might take a while for the first time, but will NOT be repeated every time
LIB_FLAGS 				:= $(addprefix -L,$(LIB_DIRS))


#######################################
### Includes
# LBL_IncludeDirectories
#######################################

### Recursively add project include folder
INC_DIRS 				:= $(shell find . -wholename "*$(INC_DIR)*" -type d)

### Recursively add project src folder
INC_DIRS 				+= $(SRC_DIRS)

### Recursively add project test folder
ifeq ($(TESTMODE),true)
    INC_DIRS 				+= $(TEST_DIRS)
endif

### Get the locations of system header files; ignore for emscripten
ifeq ($(PLATFORM),web)
	### Emscripten must not use system includes
    INC_DIRS			+=
else
    INC_DIRS 			+= $(USR)/include
    
    ifeq ($(OS),linux)
        INC_DIRS 		+= $(USR)/local/include
    endif
endif


# LBL_IncludeDirectories_ProjectSpecific
SYS_INC_DIRS 			+= $(LIB_DIR)
SYS_INC_DIRS 			+= $(RAYLIB_SRC_DIR)
SYS_INC_DIRS 			+= $(RAYLIB_SRC_DIR)/external


# LBL_IncludeFlags
### Make include flags by prefixing every provided path
INC_FLAGS 				= $(addprefix -I,$(INC_DIRS))
INC_FLAGS 				+= $(addprefix -isystem,$(SYS_INC_DIRS))


#######################################
### Toolchain
# LBL_Toolchain
#######################################

ifeq ($(PLATFORM),unix)
    CXX 				:= clang++
endif
ifeq ($(PLATFORM),windows)
    CXX 				:= /bin/x86_64-w64-mingw32-g++
endif
ifeq ($(PLATFORM),web)
    CXX 				:= em++
endif


# LBL_CompileFlags
### Set compile flags
# -MMD 				provides dependency information (header files) for make in .d files 
# -pg 				ADD FOR gprof analysis TO BOTH COMPILE AND LINK COMMAND!!
# -MJ 				CLANG ONLY: compile-database
# -MP 				Multi-threaded compilation
# -Wfatal-errors 	Stop at first error

### Default flags
#-DVERSION=$(VERSION)
CXX_FLAGS 				:= -std=c++20 -MMD -MP
FATAL					:= false

### Build specific flags 
ifeq ($(NOGUI),true)
    CXX_FLAGS				+= -DNOGUI
endif
ifeq ($(OS),linux)
    CXX_FLAGS 				+= 
    ifeq ($(OS),termux)
        CXX_FLAGS 				+= -DTERMUX
    endif
endif

# Define RELEASE in debug builds to keep lsp working for release only code
ifeq ($(PLATFORM),web)
    CXX_FLAGS 			+= -Os -Wall -DEMSCRIPTEN -DPLATFORM_WEB
    ifeq ($(BUILD),debug)
        CXX_FLAGS 			+= -g -Wall -DDEBUG
    else
        CXX_FLAGS 			+= -DNDEBUG
    endif
else
    ifeq ($(BUILD),debug)
        CXX_FLAGS 			+= -g -ggdb -O0 -Wall -Wextra -Wshadow -Werror -Wpedantic -pedantic-errors -DDEBUG
        ifeq ($(FATAL),true)
            CXX_FLAGS			+= -Wfatal-errors
        endif

        ifeq ($(OS),linux)
            CXX_FLAGS 		+= -pg
        endif
    else
        CXX_FLAGS 		+= -O2 -DNDEBUG
    endif
endif


# LBL_LinkFlags
### Set link flags
LD_FLAGS 			:= -lpthread #-fsanitize=address

ifeq ($(PLATFORM),web)
    LD_FLAGS 			+= --preload-file $(ASSETS_DIR)/ -sUSE_GLFW=3
    ifeq ($(BUILD),debug)
        LD_FLAGS 			+= --shell-file $(RAYLIB_SRC_DIR)/shell.html
    else
        LD_FLAGS 			+= --shell-file $(RAYLIB_SRC_DIR)/minshell.html
    endif
endif
ifeq ($(PLATFORM),windows)
    LD_FLAGS 			+= -static -static-libgcc -static-libstdc++
endif

### Make link flags by prefixing every provided library with -l (should work for most libraries due to convention); probably pkg-config makes duplicates...
LD_FLAGS 			+= $(addprefix -l,$(LIBRARIES))


#######################################
### Rules
# LBL_Rules
#######################################

### Set VPATH as std dir to find sources in subdirs
# Should not be needed: https://www.cmcrossroads.com/article/basics-vpath-and-vpath
# VPATH 					:= $(shell find ./$(SRC_DIR) -type d):$(shell find ./$(INC_DIR) -type d)#:$(shell find ./$(BUILD_DIR) -type d)#:$(shell find . -type d)
# better:
vpath %$(SRC_EXT) $(SRC_DIRS)
ifeq ($(TESTMODE),true)
    vpath %$(SRC_EXT) $(TEST_DIRS)
endif

### Non-file (.phony)targets (aka. rules)
.PHONY: all analyze build bd br bt bwd bwr clean dtb init publish run rd rr rt web windows 

### Default rule by convention
all: bd br

### CppCheck static analysis
analyze:
	@cppcheck \
		--quiet \
		--enable=all \
		--suppress=missingIncludeSystem \
		--suppress=missingInclude \
		--suppress=selfAssignment \
		--suppress=cstyleCast \
		--suppress=unmatchedSuppression \
		--inconclusive \
		--check-level=exhaustive \
		--cppcheck-build-dir=$(BUILD_DIR_ROOT)/cppcheck \
		--template=gcc \
		-I include/ \
		-I src/ \
		-i lib/ \
		src/

### Build binary with current config
build: $(BIN_DIR)/$(BIN)$(BIN_EXT)

bd: 
	$(info )
	$(info === Debug build ===)
	@$(MAKE) BUILD=debug build
	@$(MAKE) -s dtb
	@$(MAKE) analyze

### Rule for release build process with binary as prerequisite
br: 
	$(info )
	$(info === Release build ===)
	@$(MAKE) BUILD=release build

bt:
	$(info )
	$(info === Test build ===)
	@$(MAKE) TESTMODE=true build

bwd:
	@$(MAKE) PLATFORM=web BUILD=debug build

bwr:
	@$(MAKE) PLATFORM=web BUILD=release build

### Clear dynamically created directories
clean:
	$(info )
	$(info === Clean ===)
	@rm -rf $(BIN_DIR_ROOT)/unix/debug/*
	@rm -rf $(BIN_DIR_ROOT)/web/debug/*
	@rm -rf $(BIN_DIR_ROOT)/windows/debug/*
	@rm -rf $(BIN_DIR_ROOT)/unix/release/*
	@rm -rf $(BIN_DIR_ROOT)/web/release/*
	@rm -rf $(BIN_DIR_ROOT)/windows/release/*
	@rm -rf $(BUILD_DIR_ROOT)/unix/debug/*
	@rm -rf $(BUILD_DIR_ROOT)/web/debug/*
	@rm -rf $(BUILD_DIR_ROOT)/windows/debug/*
	@rm -rf $(BUILD_DIR_ROOT)/unix/release/*
	@rm -rf $(BUILD_DIR_ROOT)/web/release/*
	@rm -rf $(BUILD_DIR_ROOT)/windows/release/*
	@rm -rf $(BUILD_DIR_ROOT)/cppcheck/*

### Debug build
### Build compile_commands.json
dtb:
	$(info )
	$(info === Build compile_commands.json ===)
	$(shell sed -e '1s/^/[\n/' -e '$$s/,$$/\n]/' $(BUILD_DIR)/*.o.json > compile_commands.json)

### Create necessary folders
init:
	$(info )
	$(info === Init ===)
	@mkdir -p $(BIN_DIR_ROOT)/unix/debug/
	@mkdir -p $(BIN_DIR_ROOT)/web/debug/
	@mkdir -p $(BIN_DIR_ROOT)/windows/debug/
	@mkdir -p $(BIN_DIR_ROOT)/unix/release/
	@mkdir -p $(BIN_DIR_ROOT)/web/release/
	@mkdir -p $(BIN_DIR_ROOT)/windows/release/
	@mkdir -p $(BUILD_DIR_ROOT)/unix/debug/
	@mkdir -p $(BUILD_DIR_ROOT)/web/debug/
	@mkdir -p $(BUILD_DIR_ROOT)/windows/debug/
	@mkdir -p $(BUILD_DIR_ROOT)/unix/release/
	@mkdir -p $(BUILD_DIR_ROOT)/web/release/
	@mkdir -p $(BUILD_DIR_ROOT)/windows/release/
	@mkdir -p $(BUILD_DIR_ROOT)/cppcheck/

### Rule for complete compilation, ready to publish
publish:
	$(info )
	$(info === Publish ===)
	@$(MAKE) all web windows -j

### Run binary file
run: 
	$(BIN_DIR_ROOT)/$(PLATFORM)/$(BUILD)/$(BIN)$(BIN_EXT) $(EXEC_ARGS)

rd:
	@$(MAKE) bd -j
	@$(MAKE) BUILD=debug run

rr:
	@$(MAKE) br -j
	@$(MAKE) BUILD=release run

rt:
	@$(MAKE) bt -j
	@$(MAKE) TESTMODE=true run

### Rule for web build process
web:
	$(info )
	$(info === Web build ===)
	@$(MAKE) bwd bwr -j

### Rule for windows build process
windows:
	$(info )
	$(info === Windows build ===)
	@$(MAKE) PLATFORM=windows BUILD=release build


# LBL_BuildRules
### $@ (target, left of ":")
### $< (first dependency, first right of ":")
### $^ (all dependencies, all right of ":")

# === COMPILER COMMAND ===
### MAKE object files FROM source files; "%" pattern-matches (need pair of)
$(BUILD_DIR)/%$(OBJ_EXT) : %$(SRC_EXT) 
	$(info )
	$(info === Compile: PLATFORM=$(PLATFORM), BUILD=$(BUILD) ===)
	$(CXX) -o $@ -c $< $(CXX_FLAGS) $(INC_FLAGS)

### Need separate compiler command for -MJ flag argument
$(BUILD_DIR_ROOT)/unix/debug/%$(OBJ_EXT) : %$(SRC_EXT) 
	$(info )
	$(info === Compile: PLATFORM=$(PLATFORM), BUILD=$(BUILD) ===)
	$(CXX) -o $@ -c $< $(CXX_FLAGS) $(INC_FLAGS) -MJ $@.json 


# === LINKER COMMAND ===
### MAKE binary file FROM object files
$(BIN_DIR_ROOT)/$(PLATFORM)/$(BUILD)/$(BIN)$(BIN_EXT) : $(OBJS)
	$(info )
	$(info === Link: PLATFORM=$(PLATFORM), BUILD=$(BUILD) ===)
	$(CXX) -o $@ $^ $(CXX_FLAGS) $(LIB_FLAGS) $(LD_FLAGS)


### "-" surpresses error for initial missing .d files
-include $(DEPS)
