module Riki
  # Redirections may change, therefore when asking for freshness of a cache entry, we need to check with the server
  # whether our stored redirect is still current. As it seems that there is no way to query the timestamp of a redirect,
  # we might as well just ask whether the redirect target is the same as the cached redirect.
  #
  # If still current, we attempt to resolve the redirect locally, and check this result again for freshness.
  #
  # If one of these checks yields that the locally stored page is stale, we fetch it again and overwrite the stale
  # cache entry.
  #
  # Sample result from asking for "Mimia" (including the quotes, encoded as %22 in the URL):
  #
  # <?xml version="1.0"?>
  # <api xmlns="http://www.mediawiki.org/xml/api/">
  #   <query>
  #     <pages>
  #       <page pageid="25594972" ns="0" title="&quot;Mimia&quot;">
  #         <revisions>
  #           <rev timestamp="2012-03-29T07:22:51Z" xml:space="preserve">#REDIRECT [[Mimipiscis]]</rev>
  #         </revisions>
  #       </page>
  #     </pages>
  #   </query>
  # </api>
  #
  class Redirection
    attr_reader :from, :to
  end
end
