require "open3"

def execute_py(py_name, stdin)
  py_path = File.expand_path("../firebase/#{py_name}.py", __FILE__)
  command = "python3 #{py_path}"
  p command
  o, s = Open3.capture2(command, :stdin_data => stdin)
  o
end

def create_custom_token(uid)
  execute_py('create_custom_token', uid)
end

