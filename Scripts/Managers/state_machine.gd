class_name StateMachine
extends RefCounted

var _states : Dictionary # {name:{to, from, process, ph_process}
var _curr_state : String

func add_state(state_name : String, switch_to_func : Callable, switch_from_func : Callable, process_func : Callable, physics_process_func : Callable):
	assert(_states.has(state_name) == false, "state name already exists")
	_states[state_name] = {"to":switch_to_func, "from":switch_from_func, "process":process_func, "ph_process":physics_process_func}

func get_current_state() -> String:
	return _curr_state

func change_state(to : String):
	if _curr_state.is_empty() == false && _states[_curr_state]["from"].is_null() == false:
		_states[_curr_state]["from"].call(to)
		
	var from : String = _curr_state
	_curr_state = to
	
	if _states[_curr_state]["to"].is_null() == false:
		_states[_curr_state]["to"].call(from)

func state_process(delta : float):
	if _curr_state.is_empty(): return
	
	var function : Callable = _states[_curr_state]["process"]
	if function.is_null() == false:
		function.call(delta)

func state_physics_process(delta : float):
	if _curr_state.is_empty(): return
	
	var function : Callable = _states[_curr_state]["ph_process"]
	if function.is_null() == false:
		function.call(delta)
