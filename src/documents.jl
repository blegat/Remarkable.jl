abstract type RemarkableObject end

@with_kw struct Document <: RemarkableObject
    ID::String = string(uuid4())
    Version::Int = 1
    Message::String = ""
    Success::Bool = true
    BlobURLGet::String = ""
    BlobURLGetExpires::String = string(DateTime(0))
    BlobURLPut::String = ""
    BlobURLPutExpires::String = string(DateTime(0))
    ModifiedClient::String = string(DateTime(now(UTC))) * "Z"
    VissibleName::String = "new document"
    CurrentPage::Int = 1
    Bookmarked::Bool = false
    Type::String = "DocumentType"
    Parent::String = ""
end

doc_color = crayon"blue"
pdf_color = crayon"red"
col_color = crayon"green"
reset_color = Crayon(; reset=true)

@with_kw struct Collection <: RemarkableObject
    ID::String = string(uuid4())
    Version::Int = 1
    Message::String = ""
    Success::Bool = true
    BlobURLGet::String = ""
    BlobURLGetExpires::String = string(DateTime(0))
    BlobURLPut::String = ""
    BlobURLPutExpires::String = string(DateTime(0))
    ModifiedClient::String = string(DateTime(now(UTC))) * "Z"
    VissibleName::String = "new folder"
    CurrentPage::Int = 0
    Bookmarked::Bool = false
    Type::String = "CollectionType"
    Parent::String = ""
    objects::Vector{RemarkableObject} = RemarkableObject[]
end

function Document(dict::Dict{String,Any})
    return Document(; Dict(Symbol(key) => value for (key, value) in dict)...)
end
function Collection(dict::Dict{String,Any})
    return Collection(; Dict(Symbol(key) => value for (key, value) in dict)...)
end

Base.getindex(c::Collection, i::Int) = c.objects[i]
Base.iterate(c::Collection, state) = iterate(c.objects, state)
Base.iterate(c::Collection) = iterate(c.objects)
Base.length(c::Collection) = length(c.objects)

AbstractTrees.children(::Document) = ()
AbstractTrees.children(c::Collection) = c.objects

title(x::RemarkableObject) = x.VissibleName

ispdf(d::Document) = endswith(d.VissibleName, ".pdf")

function AbstractTrees.printnode(io::IO, d::Document)
    return print(io, ispdf(d) ? pdf_color : doc_color, d.VissibleName, reset_color)
end
function AbstractTrees.printnode(io::IO, c::Collection)
    return print(io, col_color, c.VissibleName, reset_color)
end

function create_tree(docs::AbstractVector{<:RemarkableObject})
    root = Collection(; ID="", VissibleName="Root")
    push!(root.objects, Collection(; ID="Trash", VissibleName="Trash"))
    update_obj!(root, docs) # Recursive loop on documents
    return root
end

function update_obj!(col::Collection, docs)
    for doc in docs
        if doc.Parent == col.ID
            update_obj!(doc, docs)
            push!(col.objects, doc)
        end
    end
end

update_obj!(::Document, ::Any) = nothing

function obj_to_dict(doc::Document)
    dict = type2dict(doc)
    return Dict(string(key) => value for (key, value) in dict)
end

function obj_to_dict(col::Collection)
    dict = type2dict(col)
    delete!(dict, :objects)
    return Dict(string(key) => value for (key, value) in dict)
end

function find_col(f, client::RemarkableClient, col::Collection=list_items(client))
    if f(col)
        return col
    end
    for c in col
        res = find_col(f, client, c)
        isnothing(res) ? nothing : return res
    end
    return nothing
end

find_col(f, client::RemarkableClient, col::Document) = nothing
