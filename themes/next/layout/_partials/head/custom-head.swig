{#
Custom head.
#}

<link href="{{ url_for(theme.vendors._internal + '/mermaid/mermaid.css') }}" rel="stylesheet">
<script src="{{ url_for(theme.vendors._internal + '/mermaid/mermaid.min.js') }}"></script>
<script type="text/javascript">mermaid.initialize({startOnLoad:true});</script>
