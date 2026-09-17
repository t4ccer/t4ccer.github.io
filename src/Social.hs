module Social (socialCompiler) where

import Data.Text qualified as T
import Hakyll.Core.Compiler (Compiler)
import Hakyll.Core.Item (Item)
import Hakyll.Web.Pandoc (defaultHakyllReaderOptions, defaultHakyllWriterOptions, pandocCompilerWithTransform)
import Text.Pandoc.Definition (Format (Format), Inline (Link, RawInline))
import Text.Pandoc.Shared (stringify)
import Text.Pandoc.Walk (walk)

socialCompiler :: Compiler (Item String)
socialCompiler = pandocCompilerWithTransform defaultHakyllReaderOptions defaultHakyllWriterOptions (walk iconLink)

-- Links written as `[Label](url){.icon-class}` become icon-only anchors,
-- links without classes are left untouched.
iconLink :: Inline -> Inline
iconLink (Link (ident, classes@(_ : _), attrs) label (url, _)) =
    Link (ident, [], linkAttrs <> attrs) [icon] (url, title)
  where
    title = stringify label
    linkAttrs = [("target", "_blank"), ("rel", "me"), ("aria-label", title)]
    icon = RawInline (Format "html") ("<i class=\"" <> T.unwords classes <> "\" aria-hidden=\"true\"></i>")
iconLink inline = inline
