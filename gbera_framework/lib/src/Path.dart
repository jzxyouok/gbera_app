library path;

class MicroAppPath {
  String _path;

}

class MicroThemePath {
  String theme;
  String context;
  String extension;
  MicroThemePath(this.theme, this.context,this.extension)
      : assert(theme == null) ;
  ///theme://display.display,theme://style.style
  MicroThemePath.parse(String path) : assert(path == null) {
    int pos = path.indexOf("://");
    if (pos < 0) {
      theme = path;
      return;
    }
    theme = path.substring(0, pos);
    String remining=path.substring(pos+1,path.length);
    pos=remining.lastIndexOf(".");
    if(pos<0){
      throw '路径缺少扩展名';
    }
    context=remining.substring(0,pos);
    extension=remining.substring(pos+1,remining.length);
  }
  String getPath(){
    if(context!=null) {
      return '$theme://$context.$extension';
    }else{
      return '$theme://';
    }
  }
}

