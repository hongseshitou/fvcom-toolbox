function write_FVCOM_spectide(ObcNodes,Period,Phase,Amp,SpectralFile,MyTitle) 
	
% Write an FVCOM spectral tidal elevation forcing file 
%
% function write_FVCOM_spectide(ObcNodes,Period,Phase,Amp,SpectralFile,MyTitle)   
%
% DESCRIPTION:
%    Write an FVCOM NetCDF spectral tidal elevation forcing file
%
% INPUT:
%   ObcNodes     = list of open boundary nodes of size [nObcs]
%   Period       = list of periods in seconds of size [nComponents]
%   Phase        = list of phases in degrees of size [nObcs,nComponents]
%   Amp          = list of amplitudes (m) of size [nObcs,nComponents]
%   SpectralFile = name of NetCDF file
%   MyTitle      = case title, written as global attribute of NetCDF file
%
% OUTPUT:
%    SpectralFile, A NetCDF FVCOM spectral tide forcing file
%
% EXAMPLE USAGE
%    write_FVCOM_spectide(ObcNodes,Period,Phase,Amp,SpectralFile,MyTitle) 
%
% Author(s):  
%    Geoff Cowles (University of Massachusetts Dartmouth)
%    Pierre Cazenave (Plymouth Marine Laboratory)
% 
% Revision history
%    2012-06-14 Ported NetCDF write to use MATLAB's native NetCDF support.
%    Requires MATLAB v2010a or greater.
%   
%==============================================================================
warning off

global ftbverbose 
report = false;
if(ftbverbose); report = true; end;
subname = 'write_FVCOM_spectide';
if(report);  fprintf('\n'); end;
if(report); fprintf(['begin : ' subname '\n']); end;
%------------------------------------------------------------------------------
% Sanity check on input and dimensions
%------------------------------------------------------------------------------
nComponents = numel(Period);
if(report); fprintf('Number of Tide Components %d\n',nComponents); end;

nObcs = numel(ObcNodes);
if(report); fprintf('Number of Open Boundary Nodes %d\n',nObcs); end;

[chk1,chk2] = size(Amp);
if( (nObcs-chk1)*(nComponents-chk2) ~= 0)
	fprintf('Amp dimensions do not match!!!')
	fprintf('nObcs %d nComponens %d\n',chk1,chk2)
	error('bad');
end;

[chk1,chk2] = size(Phase);
if( (nObcs-chk1)*(nComponents-chk2) ~= 0)
	fprintf('Phase dimensions do not match!!!')
	fprintf('nObcs %d nComponens %d\n',chk1,chk2)
	error('bad');
end;

%%
%------------------------------------------------------------------------------
% Dump the file
%------------------------------------------------------------------------------

nc=netcdf.create(SpectralFile,'clobber');

% define global attributes
netcdf.putAtt(nc,netcdf.getConstant('NC_GLOBAL'),'type','FVCOM SPECTRAL ELEVATION FORCING FILE')
netcdf.putAtt(nc,netcdf.getConstant('NC_GLOBAL'),'title',MyTitle)
netcdf.putAtt(nc,netcdf.getConstant('NC_GLOBAL'),'history','FILE CREATED using write_FVCOM_spectide')

% define dimensions
nobc_dimid=netcdf.defDim(nc,'nobc',nObcs);
tidal_components_dimid=netcdf.defDim(nc,'tidal_components',nComponents);
date_str_len_dimid=netcdf.defDim(nc,'DateStrLen',[26,nComponents]);

% define variables and attributes
nobc_varid=netcdf.defVar(nc,'obc_nodes','NC_INT',nobc_dimid);
netcdf.putAtt(nc,nobc_varid,'long_name','Open Boundary Node Number');
netcdf.putAtt(nc,nobc_varid,'grid','obc_grid');

tide_period_varid=netcdf.defVar(nc,'tide_period','NC_FLOAT',tidal_components_dimid);
netcdf.putAtt(nc,tide_period_varid,'long_name','tide angular period');
netcdf.putAtt(nc,tide_period_varid,'units','seconds');

tide_Eref_varid=netcdf.defVar(nc,'tide_Eref','NC_FLOAT',nobc_dimid);
netcdf.putAtt(nc,tide_Eref_varid,'long_name','tidal elevation reference level');
netcdf.putAtt(nc,tide_Eref_varid,'units','meters');

tide_Ephase_varid=netcdf.defVar(nc,'tide_Ephase','NC_FLOAT',[nobc_dimid,tidal_components_dimid]);
netcdf.putAtt(nc,tide_Ephase_varid,'long_name','tidal elevation phase angle');
netcdf.putAtt(nc,tide_Ephase_varid,'units','degrees, time of maximum elevation with respect to chosen time origin');

tide_Eamp_varid=netcdf.defVar(nc,'tide_Eamp','NC_FLOAT',[nobc_dimid,tidal_components_dimid]);
netcdf.putAtt(nc,tide_Eamp_varid,'long_name','tidal elevation amplitude');
netcdf.putAtt(nc,tide_Eamp_varid,'units','meters');

equilibrium_tide_Eamp_varid=netcdf.defVar(nc,'equilibrium_tide_Eamp','NC_FLOAT',tidal_components_dimid);
netcdf.putAtt(nc,equilibrium_tide_Eamp_varid,'long_name','equilibrium tidal elevation amplitude');
netcdf.putAtt(nc,equilibrium_tide_Eamp_varid,'units','meters');

equilibrium_beta_love_varid=netcdf.defVar(nc,'equilibrium_beta_love','NC_FLOAT',tidal_components_dimid);
netcdf.putAtt(nc,equilibrium_beta_love_varid,'formula','beta=1+klove-hlove');

date_str_len_varid=netcdf.defVar(nc,'equilibrium_tide_type','NC_CHAR',[date_str_len_dimid,tidal_components_dimid]);
netcdf.putAtt(nc,date_str_len_varid,'long_name','formula');
netcdf.putAtt(nc,date_str_len_varid,'units','beta=1+klove-hlove');

time_origin_varid=netcdf.defVar(nc,'time_origin','NC_FLOAT',[]);
netcdf.putAtt(nc,time_origin_varid,'long_name','time');
netcdf.putAtt(nc,time_origin_varid,'units','days since 0.0');
netcdf.putAtt(nc,time_origin_varid,'time_zone','none');

% end definitions
netcdf.endDef(nc);

% write data
netcdf.putVar(nc,nobc_varid,ObcNodes);
netcdf.putVar(nc,tide_period_varid,Period);
netcdf.putVar(nc,tide_Eref_varid,zeros(1,nObcs));
netcdf.putVar(nc,tide_Ephase_varid,Phase);
netcdf.putVar(nc,tide_Eamp_varid,Amp);
netcdf.putVar(nc,equilibrium_tide_Eamp_varid,zeros(1,nComponents));
netcdf.putVar(nc,equilibrium_beta_love_varid,zeros(1,nComponents));

nStringOut=char();
for i=1:nComponents
    nStringOut = [nStringOut, 'SEMIDIURNAL               '];
end
netcdf.putVar(nc,date_str_len_varid,nStringOut);
netcdf.putVar(nc,time_origin_varid,0);

% close file
netcdf.close(nc);

if(report); fprintf(['end   : ' subname '\n']); end;

