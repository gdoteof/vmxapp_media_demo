VMX.callback=function(detections){
  console.log("something from the server!:", detections);
  return;
}


vmxApi('pauseHand').onEnter(
  toggle_pause,
  null, 
  {minTime:3000}
);

vmxApi('goForward').onEnter(
  jump_forward,
  null, 
  {minTime:3000}
);

vmxApi('goBackward').onEnter(
  jump_backward,
  null, 
  {minTime:3000}
);

function toggle_pause(){
  _run_bash("./toggle_pause", [], "", success, error);
}

function jump_forward(){
  _run_bash("./go_forward", [], "", success, error);
}

function jump_backward(){
  _run_bash("./go_backward", [], "", success, error);
}


function _run_bash(command, args, stdin, successCallback, failCallback){
  $.ajax({
      type: "POST",
      url: "http://0.0.0.0:3000/",
      dataType: "json",
      contentType:"application/json; charset=utf-8",
      data: JSON.stringify({ command: command, args: args }),
      error: failCallback,
      success: successCallback
  });
}


function success(data, status, jqxhr){
  console.log("we got good things");
  console.log(status, data);
}

function error(jxqxr, status, thrown){
  console.log("we got bad things");
  console.log("ERROR:", thrown, status)

}


