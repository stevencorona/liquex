defmodule Liquex do
  @moduledoc """
  Liquid template renderer for Elixir with 100% compatibility with the
  [Liquid](https://shopify.github.io/liquid/) gem by [Shopify](https://www.shopify.com/).

  ## Basic Usage

      iex> {:ok, template_ast} = Liquex.parse("Hello {{ name }}!")
      iex> {content, _context} = Liquex.render(template_ast, %{"name" => "World"})
      iex> content |> to_string()
      "Hello World!"

  ## Supported features

  Currently, all standard Liquid tags, filters, and types are fully supported.  Liquex can
  be considered a byte for byte drop in replacement of the Liquid gem.

  ## Lazy variables

  Liquex allows resolver functions for variables that may require some extra
  work to generate. For example, Shopify has variables for things like
  available products. Pulling all products every time would be too expensive
  to do on every render. Instead, it would be better to lazily pull that
  information as needed.

  Instead of adding the product list to the context variable map, you can add
  a function to the variable map. If a function is accessed in the variable
  map, it is executed.

      products_resolver = fn _parent -> Product.all() end

      with {:ok, document} <- Liquex.parse("There are {{ products.size }} products"),
          {result, _} <- Liquex.render(document, %{products: products_resolver}) do
        result
      end

      iex> "There are 5 products"

  ## Indifferent access

  By default, Liquex accesses your maps and structs that may have atom or
  string (or other type) keys. Liquex will try a string key first. If that
  fails, it will fall back to using an atom keys.  This is similar to how
  Ruby on Rails handles many of its hashes.

  This allows you to pass in your structs without having to replace all your
  keys with string keys.

      iex> {:ok, template_ast} = Liquex.parse("Hello {{ name }}!")
      iex> {content, _context} = Liquex.render(template_ast, %{name: "World"})
      iex> content |> to_string()
      "Hello World!"

  ## Custom filters

  Liquex contains the full suite of standard Liquid filters, but you may find that there are still
  filters that you may want to add.

  Liquex supports adding your own custom filters to the render pipeline.  When creating the context
  for the renderer, set the filter module to your own module.

      defmodule CustomFilter do
        # Import all the standard liquid filters
        use Liquex.Filter

        def scream(value, _), do: String.upcase(value) <> "!"
      end

      context = Liquex.Context.new(%{}, filter_module: CustomFilter)
      {:ok, template_ast} = Liquex.parse("{{'Hello World' | scream}}"

      {result, _} = Liquex.render(template_ast, context)
      result |> to_string()

      iex> "HELLO WORLD!"

  ## Custom tags

  One of the strong points for Liquex is that the tag parser can be extended to support non-standard
  tags.  For example, Liquid used internally for the Shopify site includes a large range of tags that
  are not supported by the base Ruby gem.  These tags could also be added to Liquex by extending the
  liquid parser.


      defmodule CustomTag do
       @moduledoc false

       @behaviour Liquex.Tag

       import NimbleParsec

       @impl true
       # Parse <<Custom Tag>>
       def parse() do
        text =
  	      lookahead_not(string(">>"))
  	      |> utf8_char([])
  	      |> times(min: 1)
  	      |> reduce({Kernel, :to_string, []})
  	      |> tag(:text)

        ignore(string("<<"))
        |> optional(text)
        |> ignore(string(">>"))
       end

       @impl true
       def render(contents, context) do
        {result, context} = Liquex.render(contents, context)
        {["Custom Tag: ", result], context}
       end
      end

      defmodule CustomParser do
       use Liquex.Parser, tags: [CustomTag]
      end

      iex> document = Liquex.parse!("<<Hello World!>>", CustomParser)
      iex> {result, _} = Liquex.render(document, context)
      iex> result |> to_string()
      "Custom Tag: Hello World


  ## Installation

  Add the package to your `mix.exs` file.

      def deps do
        [{:liquex, "~> 0.7"}]
      end

  """

  alias Liquex.Context

  @type document_t :: [
          {:control_flow, [...]}
          | {:iteration, [...]}
          | {:object, [...]}
          | {:text, iodata}
          | {:variable, [...]}
          | {{:custom_tag, module()}, any}
        ]

  @spec parse(String.t(), module) :: {:ok, document_t} | {:error, String.t(), pos_integer()}
  @doc """
  Parses a liquid `template` string using the given `parser`.

  Returns a Liquex AST document or the parser error
  """
  def parse(template, parser \\ Liquex.Parser.Base) do
    case parser.parse(template) do
      {:ok, content, _, _, _, _} -> {:ok, content}
      {:error, reason, _, _, {line, _}, _} -> {:error, reason, line}
    end
  end

  @spec parse!(String.t(), module) :: document_t
  @doc """
  Parses a liquid `template` string using the given `parser`.

  Returns a Liquex AST document or raises an exception.  See also `parse/2`
  """
  def parse!(template, parser \\ Liquex.Parser.Base) do
    case parse(template, parser) do
      {:error, reason, line} ->
        raise Liquex.Error, message: "Liquid parser error: #{reason} - Line #{line}"

      {:ok, ast} ->
        ast
    end
  end

  @spec render(document_t, Context.t() | map) :: {iodata, Context.t()}
  @doc """
  Render a Liquex AST `document` with the given `context`
  """
  def render(document, context \\ %Context{})

  def render(document, %Context{} = context),
    do: Liquex.Render.render([], document, context)

  def render(document, %{} = context), do: render(document, Context.new(context))
end
