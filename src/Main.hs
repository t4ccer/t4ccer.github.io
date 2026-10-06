module Main (main) where

import Data.List (isPrefixOf)
import Hakyll.Core.Compiler (Compiler, getRoute, loadAll, loadBody, makeItem)
import Hakyll.Core.Configuration (Configuration (destinationDirectory, providerDirectory, storeDirectory, tmpDirectory), defaultConfiguration)
import Hakyll.Core.File (copyFileCompiler)
import Hakyll.Core.Identifier (toFilePath)
import Hakyll.Core.Identifier.Pattern ((.||.))
import Hakyll.Core.Item (Item (itemIdentifier))
import Hakyll.Core.Routes (gsubRoute, idRoute, setExtension)
import Hakyll.Core.Rules (Rules, compile, create, match, route)
import Hakyll.Main (hakyllWith)
import Hakyll.Web.CompressCss (compressCssCompiler)
import Hakyll.Web.Html (toUrl)
import Hakyll.Web.Html.RelativizeUrls (relativizeUrls)
import Hakyll.Web.Pandoc (defaultHakyllReaderOptions, defaultHakyllWriterOptions, pandocCompilerWith)
import Hakyll.Web.Template (loadAndApplyTemplate, templateBodyCompiler)
import Hakyll.Web.Template.Context (Context, boolField, constField, dateField, defaultContext, field, listField)
import Hakyll.Web.Template.List (recentFirst)
import Social (socialCompiler)
import System.FilePath (takeDirectory)
import Text.Pandoc.Extensions (Extension (Ext_implicit_figures), disableExtension)
import Text.Pandoc.Options (ReaderOptions (readerExtensions))

config :: Configuration
config =
    defaultConfiguration
        { providerDirectory = "web"
        , destinationDirectory = "_site"
        , storeDirectory = "_cache"
        , tmpDirectory = "_cache/tmp"
        }

-- Without this pandoc wraps every standalone image in a <figure> with the
-- alt text repeated as a visible caption.
markdownCompiler :: Compiler (Item String)
markdownCompiler = pandocCompilerWith readerOptions defaultHakyllWriterOptions
  where
    readerOptions =
        defaultHakyllReaderOptions
            { readerExtensions = disableExtension Ext_implicit_figures (readerExtensions defaultHakyllReaderOptions)
            }

postUrlField :: String -> Context a
postUrlField key = field key $ \i -> do
    let pageId = itemIdentifier i
        empty' = fail $ "No route url found for item " ++ show pageId
    fmap (maybe empty' (toUrl . takeDirectory)) $ getRoute pageId

postCtx :: Context String
postCtx =
    mconcat
        [ dateField "date" "%Y-%m-%d"
        , postUrlField "url"
        , defaultContext
        ]

applyDefault :: Context String -> Item String -> Compiler (Item String)
applyDefault ctx item =
    loadAndApplyTemplate "templates/default.html" (navField <> socialField <> ctx) item >>= relativizeUrls

navField :: Context String
navField = boolField "onPosts" $ \item -> "posts/" `isPrefixOf` toFilePath (itemIdentifier item)

socialField :: Context String
socialField = field "social" $ \_ -> loadBody "social.md"

main :: IO ()
main = hakyllWith config $ do
    match ("img/**" .||. "favicon.ico" .||. "CNAME") $ do
        route idRoute
        compile copyFileCompiler

    match "css/*" $ do
        route idRoute
        compile compressCssCompiler

    match "templates/*" $ compile templateBodyCompiler

    match "social.md" $ compile socialCompiler

    match "index.md" $ do
        route $ setExtension "html"
        compile $ markdownCompiler >>= applyDefault defaultContext

    match "posts/*.md" $ do
        route $ gsubRoute ".md" (const "/index.html")
        compile $
            markdownCompiler
                >>= loadAndApplyTemplate "templates/post.html" postCtx
                >>= applyDefault postCtx

    postList

postList :: Rules ()
postList = create ["posts/index.html"] $ do
    route idRoute
    compile $ do
        posts <- recentFirst =<< loadAll "posts/*.md"
        let ctx = listField "posts" postCtx (pure posts) <> constField "title" "Posts" <> defaultContext
        makeItem "" >>= loadAndApplyTemplate "templates/post-list.html" ctx >>= applyDefault ctx
