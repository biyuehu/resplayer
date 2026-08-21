type elementH

type component<'props>

external array: array<elementH> => elementH = "%identity"
external float: float => elementH = "%identity"
external int: int => elementH = "%identity"
external string: string => elementH = "%identity"

type fragmentProps = {children?: elementH}

@module("preact/jsx-runtime") external jsxFragment: component<fragmentProps> = "Fragment"

module Elements = {
  type props = {
    children?: elementH,
    id?: string,
    class?: string,
    style?: string,
    target?: string,
    href?: string,
    rel?: string,
    src?: string,
    alt?: string,
    title?: string,
    @as("type") type_?: string,
    value?: string,
    placeholder?: string,
    name?: string,
    min?: string,
    max?: string,
    label?: string,
  }
  external toStringDict: props => Dict.t<string> = "%identity"

  let jsx = (tagName: string, props: props) => {
    let props = props->toStringDict
    let propsString =
      props
      ->Dict.toArray
      ->Array.filterMap(((key, value)) =>
        if key != "children" {
          Some(key ++ "=\"" ++ value ++ "\"")
        } else {
          None
        }
      )
      ->Array.join(" ")
      ->ref
    if propsString.contents != "" {
      propsString := ` ${propsString.contents}`
    }

    let isSingleTagName = ["input", "img", "br", "hr", "meta", "link"]->Array.includes(tagName)

    let childrenToString = (children: 'a): string =>
      if Array.isArray(children) {
        (Obj.magic(children): array<string>)->Array.join("")
      } else {
        (Obj.magic(children): string)
      }

    switch props->Dict.get("children") {
    | Some(children) if children != %raw(`undefined`) =>
      `<${tagName}${propsString.contents}>${childrenToString(children)}</${tagName}>`
    | _ if isSingleTagName => `<${tagName}${propsString.contents} />`
    | _ => `<${tagName}${propsString.contents}></${tagName}>`
    }->string
  }

  let jsxs = jsx

  external someElement: elementH => option<elementH> = "%identity"
  external elementToString: elementH => string = "%identity"
}
