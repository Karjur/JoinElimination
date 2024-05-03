-- Knot table ---------------------------------------------------------------------------------------------------------
-- TYP_GenreType table
-----------------------------------------------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.TYP_GenreType (
    TYP_ID integer not null,
    TYP_GenreType varchar(25) not null,
    constraint pkTYP_GenreType primary key (
        TYP_ID 
    ),
    constraint uqTYP_GenreType unique (
        TYP_GenreType
    )
);
-- Knot table ---------------------------------------------------------------------------------------------------------
-- RTT_RatingType table
-----------------------------------------------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.RTT_RatingType (
    RTT_ID smallint not null,
    RTT_RatingType varchar(25) not null,
    constraint pkRTT_RatingType primary key (
        RTT_ID 
    ),
    constraint uqRTT_RatingType unique (
        RTT_RatingType
    )
);
-- ANCHORS AND ATTRIBUTES ---------------------------------------------------------------------------------------------
--
-- Anchors are used to store the identities of entities.
-- Anchors are immutable.
-- Attributes are used to store values for properties of entities.
-- Attributes are mutable, their values may change over one or more types of time.
-- Attributes have four flavors: static, historized, knotted static, and knotted historized.
-- Anchors may have zero or more adjoined attributes.
--
-- Anchor table -------------------------------------------------------------------------------------------------------
-- CI_Cinema table (with 2 attributes)
-----------------------------------------------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.MV_Movie (
    MV_ID integer generated by default as identity not null,
    MV_Dummy boolean null,
    constraint pkMV_Movie primary key (
        MV_ID 
    )
);
-- Static attribute table ---------------------------------------------------------------------------------------------
-- MV_NAM_Movie_Name table (on MV_Movie)
-----------------------------------------------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.MV_NAM_Movie_Name (
    MV_ID integer not null,
    MV_NAM_Movie_Name varchar(50) not null,
    constraint fkMV_NAM_Movie_Name foreign key (
        MV_ID
    ) references public.MV_Movie (MV_ID),
    constraint pkMV_NAM_Movie_Name primary key (
        MV_ID 
    ) include (
        MV_NAM_Movie_Name
    )
);
-- Knotted static attribute table -------------------------------------------------------------------------------------
-- MV_GER_Movie_Gerne table (on MV_Movie)
-----------------------------------------------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.MV_GER_Movie_Gerne (
    MV_ID integer not null,
    TYP_ID integer not null,
    constraint fk_A_MV_GER_Movie_Gerne foreign key (
        MV_ID
    ) references public.MV_Movie (MV_ID),
    constraint fk_K_MV_GER_Movie_Gerne foreign key (
        TYP_ID
    ) references public.TYP_GenreType (TYP_ID),
    constraint pkMV_GER_Movie_Gerne primary key (
        MV_ID 
    ) include (
        TYP_ID
    )
);
-- Static attribute table ---------------------------------------------------------------------------------------------
-- MV_ATH_Movie_Author table (on MV_Movie)
-----------------------------------------------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.MV_ATH_Movie_Author (
    MV_ID integer not null,
    MV_ATH_Movie_Author varchar(50) not null,
    constraint fkMV_ATH_Movie_Author foreign key (
        MV_ID
    ) references public.MV_Movie (MV_ID),
    constraint pkMV_ATH_Movie_Author primary key (
        MV_ID 
    ) include (
        MV_ATH_Movie_Author
    )
);
-- Knotted historized attribute table ---------------------------------------------------------------------------------
-- MV_RAT_Movie_Rating table (on MV_Movie)
-----------------------------------------------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.MV_RAT_Movie_Rating (
    MV_ID integer not null,
    RTT_ID smallint not null,
    MV_RAT_ChangedAt timestamp not null,
    constraint fk_A_MV_RAT_Movie_Rating foreign key (
        MV_ID
    ) references public.MV_Movie (MV_ID),
    constraint fk_K_MV_RAT_Movie_Rating foreign key (
        RTT_ID
    ) references public.RTT_RatingType (RTT_ID),
    constraint pkMV_RAT_Movie_Rating primary key (
        MV_ID ,
        MV_RAT_ChangedAt 
    ) include (
        RTT_ID
    )
)
--PARTITION BY RANGE (MV_RAT_ChangedAt)
;
  --CREATE TABLE public.MV_RAT_Movie_Rating_2020 PARTITION OF public.MV_RAT_Movie_Rating
  --FOR VALUES FROM ('2020-01-01 00:00:00') TO ('2021-01-01 00:00:00');	
-- Index for historized field MV_RAT_ChangedAt on table public.MV_RAT_Movie_Rating --------------
-----------------------------------------------------------------------------------------------------------------------
CREATE INDEX IF NOT EXISTS MV_RAT_Movie_Rating_MV_RAT_ChangedAt_idx ON public.MV_RAT_Movie_Rating (MV_RAT_ChangedAt);	
--CLUSTER public.MV_RAT_Movie_Rating USING MV_RAT_Movie_Rating_MV_RAT_ChangedAt_idx;

-- ATTRIBUTE TEMPORAL PERSPECTIVES ---------------------------------------------------------------------------------------
--
-- These table valued functions simplify temporal querying by providing a temporal
-- perspective of each attribute. There are three types of perspectives: latest,
-- point-in-time and now. 
--
-- The latest perspective shows the latest available information for each attribute.
-- The now perspective shows the information as it is right now.
-- The point-in-time perspective lets you travel through the information to the given timepoint.
--
-- @changingTimepoint the point in changing time to travel to
--
-- Under equivalence all these views default to equivalent = 0, however, corresponding
-- prepended-e perspectives are provided in order to select a specific equivalent.
--
-- @equivalent the equivalent for which to retrieve data
--
-- Latest perspective -------------------------------------------------------------------------------------------------
-- lMV_RAT_Movie_Rating viewed by the latest available information (may include future versions)
-----------------------------------------------------------------------------------------------------------------------
CREATE OR REPLACE VIEW public.lMV_RAT_Movie_Rating AS
SELECT DISTINCT ON (MV_ID) MV_ID
     , RTT_ID
     , MV_RAT_ChangedAt
  FROM public.MV_RAT_Movie_Rating
 ORDER 
    BY MV_ID DESC
     , MV_RAT_ChangedAt DESC
; 

-- Latest perspective -------------------------------------------------------------------------------------------------
-- lMV_Movie viewed by the latest available information (may include future versions)
-----------------------------------------------------------------------------------------------------------------------
CREATE OR REPLACE VIEW public.lMV_Movie AS
SELECT MV.MV_ID
     , NAM.MV_NAM_Movie_Name
     , kGER.TYP_GenreType AS TYP_GenreType
     , GER.TYP_ID
     , ATH.MV_ATH_Movie_Author
     , RAT.MV_RAT_ChangedAt
     , kRAT.RTT_RatingType AS RTT_RatingType
     , RAT.RTT_ID
  FROM public.MV_Movie MV
  LEFT 
  JOIN public.MV_NAM_Movie_Name NAM
    ON NAM.MV_ID = MV.MV_ID
  LEFT 
  JOIN public.MV_GER_Movie_Gerne GER
    ON GER.MV_ID = MV.MV_ID
  LEFT 
  JOIN public.TYP_GenreType kGER
    ON kGER.TYP_ID = GER.TYP_ID
  LEFT 
  JOIN public.MV_ATH_Movie_Author ATH
    ON ATH.MV_ID = MV.MV_ID
  LEFT 
  JOIN public.lMV_RAT_Movie_Rating RAT
    ON RAT.MV_ID = MV.MV_ID
  LEFT 
  JOIN public.RTT_RatingType kRAT
    ON kRAT.RTT_ID = RAT.RTT_ID;