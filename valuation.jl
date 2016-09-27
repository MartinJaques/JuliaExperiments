using DataFrames

macro TableLookup(t,returnColumn::String,indexes...)
    for(ind,val) in enumerate(indexes)
        if(ind==1)
            exp= :($t[$ind].==$val)
        else
            exp = :($exp & ($t[$ind].==$val))
        end
        @show(exp)
    end

    exp = :($t[$exp,Symbol($returnColumn)])
    #exp = :($t[$exp,:])
    @show(exp)
end
