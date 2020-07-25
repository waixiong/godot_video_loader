extends VideoPlayer


# Declare member variables here. Examples:
# var a = 2
# var b = "text"
# var http = load('http.gd').instance()
var http
var headers = [
	"User-Agent: Pirulo/1.0 (Godot)",
	"Accept: */*"
]

func _init():
	print("Initializing...")
	http = HTTPClient.new() # Create the Client.
	var err = 0
	
	err = http.connect_to_host("https://waixiong.github.io", 443) # Connect to host/port.
	assert(err == OK) # Make sure connection was OK.
	# Wait until resolved and connected.
	while http.get_status() == HTTPClient.STATUS_CONNECTING or http.get_status() == HTTPClient.STATUS_RESOLVING:
		http.poll()
		print("Connecting...")
		OS.delay_msec(500)
	assert(http.get_status() == HTTPClient.STATUS_CONNECTED) # Could not connect
	pass


# Called when the node enters the scene tree for the first time.
func _ready():
	load_network()
	stream = load("user://temp.webm")
	play()
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass

func load_network():
	# stream = load("https://waixiong.github.io/wif3003.assignment/assets/w12Video.webm")
	# var f = http.get("https://waixiong.github.io","/wif3003.assignment/assets/w12Video.webm",443,true) #domain,url,port,useSSL
	# play()
	var err = http.request(HTTPClient.METHOD_GET, "/wif3003.assignment/assets/w12Video.webm", headers) # Request a page from the site (this one was chunked..)
	assert(err == OK) # Make sure all is OK.
	
	while http.get_status() == HTTPClient.STATUS_REQUESTING:
		# Keep polling for as long as the request is being processed.
		http.poll()
		print("Requesting...")
		if not OS.has_feature("web"):
			OS.delay_msec(500)
		else:
			# Synchronous HTTP requests are not supported on the web,
			# so wait for the next main loop iteration.
			yield(Engine.get_main_loop(), "idle_frame")
	
	assert(http.get_status() == HTTPClient.STATUS_BODY or http.get_status() == HTTPClient.STATUS_CONNECTED) # Make sure request finished well.
	
	print("response? ", http.has_response()) # Site might not have a response.
	
	if http.has_response():
		# If there is a response...
		
		headers = http.get_response_headers_as_dictionary() # Get response headers.
		print("code: ", http.get_response_code()) # Show response code.
		print("**headers:\\n", headers) # Show headers.
		
		# Getting the HTTP Body
		
		if http.is_response_chunked():
			# Does it use chunks?
			print("Response is Chunked!")
		else:
			# Or just plain Content-Length
			var bl = http.get_response_body_length()
			print("Response Length: ", bl)
			
		# This method works for both anyway
		
		var rb = PoolByteArray() # Array that will hold the data.
		
		while http.get_status() == HTTPClient.STATUS_BODY:
			# While there is body left to be read
			http.poll()
			var chunk = http.read_response_body_chunk() # Get a chunk.
			if chunk.size() == 0:
				# Got nothing, wait for buffers to fill a bit.
				OS.delay_usec(1000)
			else:
				rb = rb + chunk # Append to read buffer.
		# Done!
		print("bytes got: ", rb.size())
		var text = rb.get_string_from_ascii()
		print("Text: ", text)
		
		var file = File.new()
		file.open("user://temp.webm", File.WRITE)
		file.store_buffer(rb)
		file.close()
	else:
		print('no response from http')
	pass

func _on_loading(loaded,total):
	var percent = loaded*100/total

func _on_loaded(result):
	var result_string = result.get_string_from_ascii()
	print(result_string)
